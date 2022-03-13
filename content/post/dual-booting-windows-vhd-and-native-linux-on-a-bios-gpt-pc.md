---
title: Dual-booting Windows VHD and Native Linux on a BIOS+GPT PC
date: 2021-07-09 16:40:31
Updated: 2021-07-09 16:40:31
categories: Tech
tags: 
    - Multi-boot
---

# Background

Previously I wrote a post for this dual-boot scenario. It is a little outdated. In the past year I mostly worked in the Linux environment on my old laptop, so the Windows seems not to be a necessity which occupies a dedicated partition. However, sometimes it is still needed. That is why I started thinking to improve this setup even further.

Starting from Windows 7, Windows supports boots from a VHD file which makes it so much easier to manage. Also you are able to create differencing disks which are pretty much like snapshots.

For this new configuration, my plan is to use *BIOS + GPT disk table + Native Linux + Native Windows booting from VHD + GRUB as the bootloader*.

# Partitioning

To make GPT works with BIOS. It is required to have a small partition [flagged][GRUB wiki] with `EF02`.

The partition scheme looks like this:

```
Device         Start        End   Sectors   Size Type
/dev/sda1         34       2047      2014  1007K BIOS boot
/dev/sda2       2048    1026047   1024000   500M EFI System
/dev/sda3    1026048  206546943 205520896    98G Linux filesystem
/dev/sda4  206546944  835692543 629145600   300G Linux filesystem
/dev/sda5  835692544 1465149134 629456591 300.1G Microsoft basic data
```

# Installing Linux

Any Linux distro would work. I chose Manjaro KDE this time because I found that the Pop OS made my laptop really hot sometimes (Yeah KDE is prettier).

This part should be easy. The GRUB files is going into that EFI partition. For details, check [GRUB wiki].

# Preparing to Install Windows

I'm not going to use the standard Windwos installer since I want to install it into a VHD file. To make it work we need a Windows PE environment.

## Preparing Images

Any Windows PE (Windows 7 and above) would work. The PE ISO image is going to `/boot/wepe.iso`.

Also a Windows ISO image is needed. For example a Windows 7 ISO named `windows7.iso` will be put in the Windows data partition.

## Adding Windows PE to GRUB

Boot into Linux. Download Windows PE ISO file and move it to the EFI partition (EXT4 partitions might be problematic).

To load this ISO image, `memdisk` tool from `syslinux` is required. Steps as below on Arch based distro:

```bash
# Installing syslinux
$ sudo pacman -S syslinux

# Copying `memdisk` to the boot partition
$ sudo cp /usr/lib/syslinux/bios/memdisk /boot/memdisk

# Adding Windows PE entry to GRUB. 1DB1-9C31 is the boot partition's UUID
$ sudo cat <<EOF >>/etc/grub.d/40_custom
menuentry "WePE x64" {
    search --set=root --no-floppy --fs-uuid 1DB1-9C31
    linux16 /memdisk iso ro
    initrd16 /wepe.iso
}
EOF

# Updating GRUB entries
$ sudo grub-mkconfig -o /boot/grub/grub.cfg
```

# Installing Windows to a VHD File

After adding Windows PE to the bootloader entries, it is time to switch the working environment.

Restart the PC, then keep pression `shift` key until the GRUB menu shows up. Now navigate to the Windows PE entry and get in there.

## Creating a VHD File for Windows

To create a VHD file, open a command line window and enter `diskpart`

```cmd
# Create a VHD file assuming the NTFS data partition is assigned with D:
DISKPART> create vdisk file=d:\windows7.vhd maximum=64000 type=fixed
DISKPART> select vdisk file=d:\windows7.vhd
DISKPART> attach vdisk

# Disk table type doesn't matter but using MBR for better compatibility
DISKPART> convert mbr

# Create the system partition and assign it with C:
DISKPART> create partition primary
DISKPART> format fs=ntfs quick
DISKPART> assign letter=c
DISKPART> exit 
```

Now the Windows image can be dumped into this VHD file.

## Extracting Windows Image

Mount the Windows ISO image to `E:` volume and open a command line window

```cmd
# Get the image index. For example the desired version's index is 1
> dism /get-wiminfo /wimfile=e:\sources\install.wim

# Extract the image. Where E: is the Windows ISO and C: is the VHD file
> dism /apply-image /imagefile:e:\sources\install.wim /index:1 /applydir:c:\
```

# Fixing the Windows Bootloader

Stay in Windows PE. Don't restart the PC. We still need to fix the bootloader for Windows.

Normally Windows cannot be booted with a GPT+MBR setup. And also loading the whole Windows VHD file through `memdisk` is not possible because it's too large to load into memory. To fix the boot issue a bridge is needed between Windows and GRUB.

Luckily [a small VHD image][Hack Bootmgr to boot Windows in BIOS to GPT] can still be loaded by `memdisk`.

The idea is: GRUB -> MS Bootmgr VHD -> Windows VHD

## Creating a Dedicated Bootloader Image for Windows

It is same with the process creating a VHD file for Windows system but this time it is a smaller file (32 MB).

```cmd
# Create a small bootmgr VHD file in the data partition
DISKPART> create vdisk file=d:\bootmgr.vhd maximum=32 type=fixed
DISKPART> select vdisk file=d:\bootmgr.vhd
DISKPART> attach vdisk
DISKPART> convert mbr
DISKPART> create partition primary
DISKPART> format fs=ntfs quick
DISKPART> assign letter=f
DISKPART> exit 
```

Now the `bootmgr` VHD is mounted at F:. Then write the boot record and create boot configuration files.

```cmd
> bootsect /nt60 f: /mbr
> bcdboot c:\Windows /l en-us /s f: /f bios
```

## Fixing the BCD Entry

At this point it should be working according to the [Microsoft's document][Boot to a virtual hard disk: Add a VHDX or VHD to the boot menu]. In fact it is not.

Let's check the BCD entries, in a command window:

```cmd
> bcdedit /store f:\Boot\BCD /enum

Windows Boot Manager
--------------------
identifier              {bootmgr}
device                  partition=F:
description             Windows Boot Manager
locale                  en-us
inherit                 {globalsettings}
default                 {default}
resumeobject            {fcd67427-e033-11eb-8826-cdf90e3873d0}
displayorder            {default}
toolsdisplayorder       {memdiag}
timeout                 30

Windows Boot Loader
-------------------
identifier              {default}
device                  partition=C:
path                    \Windows\system32\winload.exe
description             Windows 7
locale                  en-us
inherit                 {bootloadersettings}
osdevice                partition=C:
systemroot              \Windows
resumeobject            {fcd67427-e033-11eb-8826-cdf90e3873d0}
nx                      OptIn
detecthal               Yes
```

The `device` and `osdevice` seems to be right but once the Windows VHD is unmounted it becomes `unknown`. According to this [BCDEdit notes], BCD entry records the partition's information such as UUID to find the correct partition during bootup. In this case the partition can't be found until the VHD file is mounted. But this VHD file is not mounted automatically.

Thus we need to correct this and let `Bootmgr` locate the VHD file properly.

In a command line window:

```cmd
# The identifier must match the one which is showing above
> bcdedit /store C:\Boot\BCD /set {default} device vhd=[D:]\windows7.vhd
> bcdedit /store C:\Boot\BCD /set {default} osdevice vhd=[D:]\windows7.vhd
``` 

If we check the BCD entry again it doesn't change. But if we unmount the Windows VHD it will become:

```cmd
> bcdedit /store f:\Boot\BCD /enum

Windows Boot Manager
--------------------
identifier              {bootmgr}
device                  partition=E:
description             Windows Boot Manager
locale                  en-us
inherit                 {globalsettings}
default                 {default}
resumeobject            {fcd67427-e033-11eb-8826-cdf90e3873d0}
displayorder            {default}
toolsdisplayorder       {memdiag}
timeout                 30

Windows Boot Loader
-------------------
identifier              {default}
device                  vhd=[C:]\windows7.vhd
path                    \Windows\system32\winload.exe
description             Windows 7
locale                  en-us
inherit                 {bootloadersettings}
osdevice                vhd=[C:]\windows7.vhd
systemroot              \Windows
resumeobject            {fcd67427-e033-11eb-8826-cdf90e3873d0}
nx                      OptIn
detecthal               Yes
```

The volume letter doesn't matter, it changes dynamically. Now `bootmgr` is able to locate the VHD file correctly.

# Adding Windows to GRUB

Restart PC and get into Linux.

Modify the GRUB config file to load `bootmgr`

```bash
# Adding Windows (bootmgr) entry to GRUB. 1DB1-9C31 is the boot partition's UUID
$ sudo cat <<EOF >>/etc/grub.d/40_custom
menuentry "Windows 7" {
    search --set=root --no-floppy --fs-uuid 1DB1-9C31
    linux16 /memdisk harddisk
    initrd16 /bootmgr.vhd
}
EOF

# Updating GRUB entries
$ sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Now we can restart PC. Keep pressing `shift` on bootup to go to the GRUB menu. Select Windows entry to boot Windows.

# Fixing Windows Initialization Error

During the first time bootup, Windows might have an error showing *Windows could not complete the installation. To install Windows on this computer, restart the installation*.

To [solve][100% Solved:Windows could not complete the installation] this error:

1. Press `SHIFT + F10` to bring up the command prompt.
2. Execute `C:\windows\system32\oobe\msoobe`.
3. Wait for a while and the setup window will show up.
4. Complete the setup and restart.

# Creating a Differencing Disk

A differencing disk can be used for quick recoveries.

To create it, restart into the Windows PE environment. In a command line window:

```cmd
# Use the original VHD as base
> move d:\windows7.vhd d:\windows7_base.vhd

# Create a differencing disk based on the original one
# The name of the new differencing disk has to be the name that was recorded in the BCD
> diskpart
DISKPART> creat vdisk file=d:\windows7.vhd parent=d:\windows7_base.vhd
```

Then all changes made in the future will go into the differencing disk. If system goes wrong one day, simply deleting the the differencing disk and creating a new one would quickly recover from the crysis.

**NOTE: After creating the differencing disk, the base VHD is not supposed to be modified.**

# References
- [GRUB wiki]
- [BIOS + GPT + GRUB + Linux + Windows 折腾笔记]
- [在 VHD 中安装 Windows 7]
- [Hack Bootmgr to boot Windows in BIOS to GPT]
- [Boot to a virtual hard disk: Add a VHDX or VHD to the boot menu]
- [BCDEdit notes]
- [100% Solved:Windows could not complete the installation]

[GRUB wiki]: https://wiki.archlinux.org/title/GRUB
[BIOS + GPT + GRUB + Linux + Windows 折腾笔记]: https://wzyboy.im/post/1049.html
[在 VHD 中安装 Windows 7]: https://rimo.site/2017/02/08/install-win7-into-vhd/
[Hack Bootmgr to boot Windows in BIOS to GPT]: http://reboot.pro/index.php?showtopic=19516&page=2&#entry184489
[Boot to a virtual hard disk: Add a VHDX or VHD to the boot menu]: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/boot-to-vhd--native-boot--add-a-virtual-hard-disk-to-the-boot-menu
[BCDEdit notes]: http://www.mistyprojects.co.uk/documents/BCDEdit/files/device.htm
[100% Solved:Windows could not complete the installation]: https://www.howisolve.com/windows-could-not-complete-the-installation-solved/
