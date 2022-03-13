---
title: Setup A Gaming VM
date: 2022-03-13 17:47:25
updated: 2022-03-13 17:47:25
categories: Tech
tags: 
    - Gaming
    - KVM
    - QEMU
    - GPU Passthrough
---

# Before starting

First thing first. The reason why I prefer a gaming Windows VM rather than a native Windows box is becuase I found that most of time my works can be done on Linux. There is no reason to run a huge spyware all the time. Besides Windows is getting worse and worse. I can feel that the PC is much slower on Windowss. So it's time to ditch it as well as get rid of tons of spyware.

In this post, I'm not going to explain everything because the ArchWiki is already clear enough. This is quick guide for the setup.

# Get started

## Identify your PC is qualified

To get high graphic performance, your CPU and motherboard must support `VT-d` and `IOMMU` respectively.

If not, you can stop here and choose the traditional way to dual-boot Linux and Windows.

NOTE: you can check [PCI passthrough via OVMF[ArchWiki OVMF] prerequisite section for more information.

## Install QEMU

I wrote a script to handle this automatically so just run [this script][QEMU install script] before hands.

NOTE: I'm using Arch Linux.

## Identify discrete graphic card

In a terminal:

```bash
$ lspci -nnk

01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM204 [GeForce GTX 970] [10de:13c2] (rev a1)
    Subsystem: Gigabyte Technology Co., Ltd Device [1458:367a]
    Kernel driver in use: nouveau
    Kernel modules: nouveau
01:00.1 Audio device [0403]: NVIDIA Corporation GM204 High Definition Audio Controller [10de:0fbb] (rev a1)
    Subsystem: Gigabyte Technology Co., Ltd Device [1458:367a]
    Kernel driver in use: snd_hda_intel
    Kernel modules: snd_hda_intel
```

Take a note of the device IDs. In this example I have a Nvidia GTX970 graphic card along with a audio controller. They belong to the same group (domain) you have to take them all.

In this case I got `1458:367a` and `1458:367a`. These are the PCI devices that will be passed through to the VM. Other PCI devices can be passed too.

## Modify kernel parameter

Then we're going to turn IOMMU on and prevent host Linux loading PCI devices that we want to pass-through to the VM.

The kernel parameter passing could be different depending on the bootloader you use. In this example, I use `grub`.

Open `/etc/default/grub` with your favorite text editor. You have to add `intel_iommu=on` to the kernel parameter along with `vfio-pci.ids=10de:13c2,10de:0fbb` which contains the device IDs you got from the previous step.

```
# /etc/default/grub

# Change this line
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"

# To
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet intel_iommu=on vfio-pci.ids=10de:13c2,10de:0fbb"
```

Then update the bootloader config file.

```bash
$ sudo grub-mkconfig -o /boot/grub/grub.cfg
```

The most tricky part is done. Restart the PC now.

NOTE: You can check `dmesg` after reboot to verify IOMMU is turned on successfully.

```bash
$ sudo dmesg | grep -i -e DMAR -e IOMMU

[    0.000000] ACPI: DMAR 0x00000000BDCB1CB0 0000B8 (v01 INTEL  BDW      00000001 INTL 00000001)
[    0.000000] Intel-IOMMU: enabled
[    0.028879] dmar: IOMMU 0: reg_base_addr fed90000 ver 1:0 cap c0000020660462 ecap f0101a
[    0.028883] dmar: IOMMU 1: reg_base_addr fed91000 ver 1:0 cap d2008c20660462 ecap f010da
[    0.028950] IOAPIC id 8 under DRHD base  0xfed91000 IOMMU 1
[    0.536212] DMAR: No ATSR found
[    0.536229] IOMMU 0 0xfed90000: using Queued invalidation
[    0.536230] IOMMU 1 0xfed91000: using Queued invalidation
[    0.536231] IOMMU: Setting RMRR:
[    0.536241] IOMMU: Setting identity map for device 0000:00:02.0 [0xbf000000 - 0xcf1fffff]
[    0.537490] IOMMU: Setting identity map for device 0000:00:14.0 [0xbdea8000 - 0xbdeb6fff]
[    0.537512] IOMMU: Setting identity map for device 0000:00:1a.0 [0xbdea8000 - 0xbdeb6fff]
[    0.537530] IOMMU: Setting identity map for device 0000:00:1d.0 [0xbdea8000 - 0xbdeb6fff]
[    0.537543] IOMMU: Prepare 0-16MiB unity mapping for LPC
[    0.537549] IOMMU: Setting identity map for device 0000:00:1f.0 [0x0 - 0xffffff]
[    2.182790] [drm] DMAR active, disabling use of stolen memory
```

## Install the VM

Open virt-manager GUI and follow the guide to setup.

Some settings should be tweaked specifically:

- Overview: Change *Firmware* to `UEFI`
- CPUs:
  - Change *vCPU allocation* to the maximal host CPUs. In this case, it's `8`
  - Unselect *Copy host CPU configuration* and change *Model* to `host-passthrough`
  - Select *Manually set CPU topology*. Change *Sockets* to `1`, *Cores* to `4`, *Threads* to `2` (Physical core `4` * threads for each core `2`)
- Disk: Change *Disk bus* to `VirtIO`
- Display Spice: You don't really need it so remove it
- Video: Change to None
- PCI: Add your discrete graphic card as well as anything with it (audio controller etc.)
- USB: Mouse, keyboards, game controllers etc.

After saving the settins, the installation should start but don't install Windows yet. Instead, force power if off. Open VM settings in XML view, add following content to prevent Nvidia driver installer discovering the VM environment.

```xml
<features>
  ...
  <hyperv>
    ...
    <vendor_id state='on' value='1234567890ab'/>
    ...
  </hyperv>
  ...
  <kvm>
    <hidden state='on'>
  </kvm>
  ...
</features>
```

Alternatively, this has the same effect.

NOTE: `win11` is the VM name you've just created.

```bash
$ sudo virshpatcher --error43 --vender-id 1234567890ab win11
```

## Install virtio drivers

In the Windows VM, download the [virtio][Virtio driver] driver and install it.

NOTE: Check [ArchWiki QEMU][ArchWiki QEMU] for more info

# Post installation

If you don't want to switch monitors you can try [Looking Glass][Looking Glass] which allows you redirect VM display output to a emulated monitor.

[QEMU install script]: https://github.com/peromage/rice/blob/master/scripts/install-qemu.sh
[ArchWiki QEMU]: https://wiki.archlinux.org/title/QEMU
[ArchWiki OVMF]: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
[Looking Glass]: https://looking-glass.io/
[Virtio driver]: https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md
