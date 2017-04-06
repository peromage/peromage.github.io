---
title: Windows + Linux 双系统引导手记
comments: true
date: 2017-04-05 19:26:41
updated: 2017-04-05 19:26:41
categories: Fixit
tags: ["多系统", "引导", "Windows", "Linux"]
---

# 0x00 情况简述
由于开发需要 Linux 环境，所以将老的那台笔记本改造成了双系统。  
这台电脑的基本情况是这样的，64GB 固态硬盘 + 720GB 机械硬盘（实际可用空间有折损，这里为了表示方便），Windows 10 已经安装到了固态硬盘上。由于主板较老，只能支持 BIOS。巨硬又说过 Windows 只能支持 BIOS + MBR，所以第一块主位（Master）上的固态硬盘就只能采用 MBR 分区表，分成了两个区，500MB 用作启动分区，剩下的部分全部划给了系统分区。  
但是 Linux 表示没有巨硬这种尿性，所以为什么不使用更先进的 GPT 分区表？因此从位（Slave）上的机械硬盘被我分成了这个样子：  
**10MB BIOS 启动分区（No File System） + 500MB /boot 启动挂载点（EXT4） + 100GB / 根挂载点（EXT4） +  199.5GB /home 用户目录挂载点（EXT4） + 420GB Windows 数据分区（NTFS）**。  
BIOS 启动分区 1MB 足以，我只是考虑到后续扩展问题。之后在第二块硬盘上安装了 Arch Linux。  

# 0x01 有啥好折腾的？
双系统安装好以后相安无事，BIOS 默认从主位固态硬盘启动。也就是说开机不进行任何操作的话，默认进入的是 Windows 10。只有在开机的时候使用 BIOS 的 Fast Boot 功能，选择从第二块硬盘启动才能进入 Arch Linux。换句话说两个系统彼此都是透明的。
但是作为一个强迫症和完美主义者，万一我想进入 Linux，但是开机的时候错过了，岂不是要重启一次才行？或者万一我又反悔想进入 Windows 又要重启一次？这怎么能忍，所以才有了这次的折腾……

# 0x02 在 GRUB 中添加引导菜单
对于 GRUB （注：这里所说的 GRUB 指的是 GRUB 2 而不是 GRUB Legacy） 引导的 Linux 来说，切换到 Windows 的 *bootmgr* 是一件很容易的事情，最新版的 GRUB 可以直接启动 *bootmgr* 而不需要之前的 chainloading 模式。
进入 Arch Linux，以 root 权限编辑 ***/etc/grub.d/40_custom*** ，加入以下菜单：  
```
menuentry "Switch to Microsoft Boot Manager" {
    insmod part_msdos
    insmod ntfs
    insmod search_fs_uuid
    insmod ntldr     
    search --fs-uuid --set=root  69B235F6749E84CE
    ntldr /bootmgr
  }
```
`insmod` 是用于加载必要的模块以便 GRUB 识别并正确启动 Windows。值得注意的是，`search` 一行指定的 UUID 与 Linux 下 **`lsblk -f`** 看到的 UUID 是不一样的，需要使用 **`sudo grub-probe --target=fs_uuid -d /dev/sda1`** 来获取 GRUB 下对应的分区 UUID。这个例子中，Windows 启动分区是 *sda1*。UUID 是唯一的，勿照搬。  

当然也可以使用传统的 chainloading 模式：  
```
menuentry "Switch to Microsoft Boot Manager" {
    insmod part_msdos
    insmod ntfs
    insmod search_fs_uuid  
    search --fs-uuid --set=root  69B235F6749E84CE
    chainloader +1
  }
```

保存以后，执行 **`sudo grub-mkconfig -o /boot/grub/grub.cfg`** ，以便更新启动菜单。  
不推荐直接编辑 ***/boot/grub/grub.cfg***，因为上述命令会覆盖这个文件，不便于自定义菜单的管理。  
这样就可以直接跳转到 *bootmgr*，让它去启动 Windows。  

# 0x03 BCD 寻思
BCD 是Windows Vista 之后使用的一种启动管理器。有个非常蛋疼的问题就在于，BCD 并不支持 EXT4 分区格式，所以没有办法读到 GRUB。查阅了相关资料，给出的解决办法就是，将 ***/boot*** 分区格式化成 FAT32 的文件系统。难道我还得再折腾一次文件系统？直觉告诉我一定还有其他的办法。  
既然 BCD 没办法直接读 EXT4 分区里面的东西，我们可以曲线救国。BCD 里面提供了一种实模式启动的方式，允许读取一个包含了启动代码的文件。所以一种解决办法就是 **BCD → MBR → VBR → Bootloader**。由于 GPT 磁盘的第一个扇区被划分成了 Protective MBR，用于兼容 BIOS，所以在 Linux 使用：  
**`sudo dd if=/dev/sdb of=/mnt/reserved/grub.bin bs=512 count=1`**  
可以将第二块硬盘的第一扇区里面的启动代码导出到一个文件，然后使用 BCD 加载这个文件就可以启动 GRUB了。  
果真如此？  
事实是，这种方法可行，但是并不适用我的情况，因为这是建立在 Windows 和 Linux 安装在同一块硬盘上的情形。*grub.bin* 并不能够跨分区寻找 VBR。难道只能作罢？肯定不可能，不然就没有这篇文章了。  
查阅了若干文档之后，得知 GRUB 提供了一个 叫做 *lnxboot.img* 文件，可以将 GRUB 启动阶段模拟成一个可以启动的 Linux 内核，然后挂载 *core.img* 里面必要的模块，从而顺利启动 GRUB。那么将之前的思路修改成 **BCD → VBR → Bootloader** 就行了，即既然 MBR 不能跨分区以及识别 GPT，那么我们就换成一个可以胜任的不就行了。  

# 0x04 制作启动镜像
进入 Arch Linux。虽然在 ***/boot/grub/i386-pc/*** 目录下有一个用于启动的 *core.img* 文件，这个文件里面指定的模块路径是相对路径，使用它启动依然会显示错误，需要指定绝对路径以保证万无一失。那么我们就来手动生成一个，顺便集成一些我们需要的模块。  
注意，启动镜像稍后会被放在 Windows 的启动分区下面（BCD 的启动分区），所以还需要知道模块所在分区的位置。在 GRUB 中表示磁盘的方式有所不同，如 *(hd0,msdos1)* 表示第一块磁盘，使用 MBR 分区表，第一个分区； *(hd1,gpt2)*  表示第二块磁盘，使用 GPT分区表，第二个分区。括号不可省，磁盘和分区的起始数字不一样。

使用  `grub-probe` 来获取 ***/boot*** 分区信息。这个例子得到的是 *hd1,gpt2*：  
**`sudo grub-probe --target=bios_hints /boot`**  

生成 *core.img*：  
**`sudo grub-mkimage --output=/tmp/core.img --prefix=\(hd1,gpt2\)/grub --format=i386-pc biosdisk part_msdos part_gpt ext2`**  
注意像我这样 ***/boot*** 单独分区，prefix 就不需要写成 ***\\(hd1,gpt2\\)/boot/grub***，毕竟已经在 ***/boot*** 里面了嘛。默认没有 GPT 支持，所以还需要添加 GPT 模块。

生成启动镜像：  
按照 GRUB 的帮助文档，*lnxboot.img* 需要放在 *core.img* 之前，由 *lnxboot.img* 来加载 *core.img*。所幸 BCD 可以一次读取大于一个扇区（512B）的内容，所以将这两个文件合并一下即可：  
**`sudo cat /usr/lib/grub/i386-pc/lnxboot.img /tmp/core.img > /tmp/grub4bcd.img`**  

然后将 *grub4bcd.img* 放到 Windows 启动分区根目录下面就可以了。注意内核默认只能以只读模式挂载 NFTS 文件系统，需要安装扩展包才能读写：  
**`sudo pacman -S ntfs-3g`**  
然后挂载（安装了上述扩展包之后甚至不用指定参数）：  
**`sudo mount /dev/sda1 /mnt/reserved`**  

现在就可以顺利地将启动镜像复制到 Windows 启动分区下面了。

# 0x05 在 BCD 中添加引导菜单
重启进入 Windows 10。以管理员权限打开命令行。  

添加入口：  
**`bcdedit /create /d "Switch to GRUB" /application bootsector`**  
会返回一串 UUID，复制下来。之后 UUID 的地方我用 **{ID}** 表示，用刚才得到的替换即可。  

设置启动分区：  
**`bcdedit /set {ID} device boot`**  

设置启动文件：  
**`Bcdedit /set {ID} path /grub4bcd.img`**  

将入口添加进启动菜单：    
**`bcdedit /displayorder {ID} /addlast`**  

关闭 Metro 启动菜单（不关闭的话切换时会重启，建议关闭）：  
**`bcdedit /set {default} bootmenupolicy legacy`**

最后关闭 Windows 10 的 Hybrid 开机功能，否则可能会导致 Windows 丢失数据：  
**`powercfg /h off`**  

# 0x06 后记
现在终于可以愉快地切换两个引导菜单了。其实使用 GRUB 来管理两个系统是较为简单的办法。  
更为简单的办法是，先装 Windows 然后装 Ubuntu，后者会自动搞定这些麻烦事。╮(╯_╰)╭  

# 0x07 参考资料
*<https://www.gnu.org/software/grub/manual/grub.html#Images>*  
*<http://askubuntu.com/questions/180033/how-to-add-different-drive-ubuntu-to-bcd-manually>*  
*<https://wiki.archlinux.org/index.php/Talk:Dual_boot_with_Windows>*  
*<https://wiki.archlinux.org/index.php/Dual_boot_with_Windows>*  
