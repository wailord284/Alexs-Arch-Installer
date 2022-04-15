# Alex's Arch Linux Installer
A simple script to automatically install a highly tuned (under the hood) Arch Linux with the XFCE desktop, custom repositories, better performance and many post install options. Add me on Discord for any thoughts/comments/concerns/issues: wailord284#3794

# How to use
To use this script, you first need to [create a bootable USB](https://www.howtogeek.com/howto/linux/create-a-bootable-ubuntu-usb-flash-drive-the-easy-way/) with the [Arch Linux ISO.](https://archlinux.org/download/) It is recommended to use the latest availible version of the ISO. Once the ISO is booted and connected to the internet (which is required), you can download the script either from github or my website using curl. Both options will be kept up to date. Make sure you run the script using bash, otherwise zsh will interpret the script and error.
To use the script, do the following:
```
curl https://wailord284.club/repo/install.sh -o install.sh
bash install.sh
```
The user will now be prompted to supply basic information such as hostname, username, password, timezone, disk to install to, disk encryption and full disk wipe. Make sure to press space before pressing enter on options that require selecting something from a list.
# Features! (in no particular order)
- Works with both UEFI (64 and 32 bit) and Legacy BIOS
- Automatic detection for Intel and AMD graphics
- Automatically detect if running in VirtualBox, KVM or VMware and install appropriate guest additions
- Optional disk encryption for the root partition
- Slightly modified XFCE configuration to enable compositing, change font and change theme
- Custom nanorc file to include syntax highlighting
- Optionally install custom kernels (linux-tkg) with GCC CPU optimizations from chaotic-aur
- Display all network interface IP Addresses on TTY logins
- Support for [EXT4](https://wiki.archlinux.org/index.php/Ext4), [XFS](https://wiki.archlinux.org/index.php/XFS), [JFS](https://wiki.archlinux.org/title/JFS), [NILFS2](https://en.wikipedia.org/wiki/NILFS), [F2FS](https://wiki.archlinux.org/title/F2FS) or [BTRFS](https://wiki.archlinux.org/index.php/Btrfs) filesystems
    * BTRFS will use [compress-force=zstd](https://wiki.archlinux.org/index.php/Btrfs#Compression) for default compression
    * BTRFS scrub timer (monthly) will be enabled for the root directory if selected
    * BTRFS autodefrag timer (monthly) will be enabled for the root directory if selected
    * All filesystems will use an *atime (usually noatime) mount option
- GPG keyserver for Pacman changed to [keyserver.ubuntu.com](https://keyserver.ubuntu.com/)
- Preconfigured GPU Accelerated terminal [Kitty](https://sw.kovidgoyal.net/kitty/)
- Automatic detection for Intel and AMD CPUs to [install correct microcode](https://wiki.archlinux.org/index.php/Microcode#Installation)
- Optionally overwrite the drive with random data to [securely erase](https://wiki.archlinux.org/index.php/Securely_wipe_disk#shred) the drive
- [Earlyoom](https://github.com/rfjakob/earlyoom) daemon to trigger the Linux OOM killer sooner
- [Kernel Modules hook](https://github.com/saber-nyan/kernel-modules-hook) to restore functionality when the running kernel updates
- [Pacman cleanup hook](https://aur.archlinux.org/packages/pacman-cleanup-hook/) to minimize the pacman cache size when updating
- [FSTrim timer](https://wiki.archlinux.org/index.php/Solid_state_drive#Periodic_TRIM) if a SSD is detected
- [Zram](https://aur.archlinux.org/packages/zramswap/) instead of swap (sets to 20% of total ram)
- [Modified IO Schedulers](https://wiki.archlinux.org/index.php/Improving_performance#Changing_I/O_scheduler) for hard drives, SSDs and NVME drives
- Change [mkinitcpio compression to ZSTD](https://wiki.archlinux.org/index.php/Mkinitcpio#COMPRESSION) (Added in kernel 5.9)
- Support for [Touchscreen devices](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/72-wacom-options.conf) (such as the Thinkpad X201T/X220T)
- Disabled ["Recents"](https://alexcabal.com/disabling-gnomes-recently-used-file-list-the-better-way) found in most file managers
- LXDM display manager with [Archlinux theme](https://aur.archlinux.org/packages/archlinux-lxdm-theme/)
- Large amount of [sysctl configs](https://wiki.archlinux.org/index.php/Sysctl#Improving_performance) gathered from the Arch wiki to increase performance and stability
- Xorg keybind [(Control + Alt + Backspace)](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/90-zap.conf) to kill the running desktop and return to the login manager
- [Archlinuxcn](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#archlinuxcn) and [chaotic-aur](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#chaotic-aur) repository for additional software
- Automatic log rotation with [logrotate](https://wiki.archlinux.org/title/Logrotate)
- [DBus-Broker](https://wiki.archlinux.org/index.php/D-Bus#dbus-broker) over traditional D-Bus for higher performance and reliability
- [Realtime priority](https://wiki.archlinux.org/index.php/Gaming#Enabling_realtime_priority_and_negative_nice_level) in Pulseaudio
- [Spindown hard drives after 20 minutes](https://wiki.archlinux.org/index.php/Hdparm#Power_management_configuration) using hdparm in udev
- [Zlib-ng](https://github.com/zlib-ng/zlib-ng) with modern features and optimizations compared to zlib
- [b43-firmware](https://wireless.wiki.kernel.org/en/users/drivers/b43/firmware) installed if missing wireless card firmware
- [Spectre](https://en.wikipedia.org/wiki/Spectre_(security_vulnerability)) and [Meltdown](https://en.wikipedia.org/wiki/Meltdown_(security_vulnerability)) mitigations can be [disabled](https://sleeplessbeastie.eu/2020/03/27/how-to-disable-mitigations-for-cpu-vulnerabilities/)
- [Systemd-timesyncd](https://wiki.archlinux.org/title/Systemd-timesyncd) for system time
- Changes if RAM is over 2GB
    * [IRQBalance](https://irqbalance.github.io/irqbalance/) - An attempt to better balance system latency and throughput on multi-core systems
    * [Prelockd](https://github.com/hakavlad/prelockd) - Daemon to lock desktop in RAM
    * [Preload](https://wiki.archlinux.org/index.php/Preload#Preload) - Daemon to load commonly used applications/files in RAM to speed up the system
    * [Uresourced](https://gitlab.freedesktop.org/benzea/uresourced) - Dynamically allocate resources to the active user 
    * [Ananicy-cpp](https://gitlab.com/ananicy-cpp/ananicy-cpp) - Daemon to automatically set the NICe value of programs
    * [Ananicy rules](https://aur.archlinux.org/packages/ananicy-rules-git/) - Extra program support for ananicy
    * Ananicy check frequency changed from 5 to 15 seconds
- Firefox changes (All installed with package manager):
    * [Ublock Origin](https://ublockorigin.com/) - Ad blocker
    * [ClearURLs](https://addons.mozilla.org/en-US/firefox/addon/clearurls/) - URL Tracker blocker
    * [User Agent Switcher](https://addons.mozilla.org/en-US/firefox/addon/uaswitcher/?utm_source=gitlab) - Change browser user agent
    * [Decentral Eyes](https://decentraleyes.org/) - Local emulation of Content Delivery Networks
- Polkit changes:
    * [Libvirt rule](https://wiki.archlinux.org/title/Libvirt#Using_polkit) - Use libvirt without password (users in the KVM group)
    * [NetworkManager rule](https://wiki.archlinux.org/title/NetworkManager#Set_up_PolicyKit_permissions) - Add/Remove a network without a password (users in the network group)
    * [GParted rule](https://wiki.archlinux.org/title/Polkit#Authorization_rules) - Allow gparted to run without a password (users in storage group)
    * [Gsmartcontrol](https://gsmartcontrol.sourceforge.io/home/) - Allows gsmartcontrol to run without a password (users in storage group)
- Bash changes:
    * [.inputrc](https://wiki.archlinux.org/index.php/Readline#Faster_completion) - Add color and improve tab completion
    * [ASCII Pokemon](https://aur.archlinux.org/packages/pokeshell/) - Display a pokemon in terminal
    * Add colored output to ls and file extensions
    * Custom aliases for yay/pacman and other system tasks
- Laptop changes (If detected):
    * [Tackpad](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/70-synaptics.conf) - More comfortable defaults
    * [TLP](https://wiki.archlinux.org/title/TLP) - Default settings and PCIE_ASPM_ON_BAT=powersupersave
    * [Powertop](https://wiki.archlinux.org/title/Powertop) - With --auto-tune enabled
- Grub changes:
    * [File Manager](https://github.com/a1ive/grub2-filemanager), Reboot and Shutdown - Available as additional grub menus
    * [UEFI tools:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/tools) UEFI Shell, GDisk partition editor, Memtest86, Super Grub Disk
    * [UEFI games:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/games) Tetris, Flappybird
    * Arch Linux [theme](https://github.com/fghibellini/arch-silence)
- Makepkg changes:
    * [Makeflags](https://wiki.archlinux.org/index.php/Makepkg#Building_optimized_binaries) - Set makeflags to use all cores
    * Change -mtune=generic to [native](https://wiki.archlinux.org/index.php/Makepkg#Building_optimized_binaries)
    * Change RUSTFLAGS to build [native](https://wiki.archlinux.org/index.php/Makepkg#Building_optimized_binaries) binaries
    * Use [.tar](https://wiki.archlinux.org/index.php/Makepkg#Use_other_compression_algorithms) as default package extension (No compression) when building AUR packages
    * Add [multithreaded](https://wiki.archlinux.org/index.php/Makepkg#Parallel_compilation) capable compression programs for supported files
    * Enable [max compression](https://wiki.archlinux.org/title/Makepkg#Utilizing_multiple_cores_on_compression) when compressing .xz and .zst (If package extension changed to .pkg.tar.xz or .zst)
    * LTO optimizations enabled
- Systemd changes:
    * [Promiscuous mode](https://wiki.archlinux.org/index.php/Network_configuration#Promiscuous_mode) - Systemd service to make packet sniffing easier (disabled by default)
    * [Journal log always visible](https://wiki.archlinux.org/index.php/Systemd/Journal#Forward_journald_to_/dev/tty12) on tty12 (control + alt + F12)
    * [Journald logs](https://wiki.archlinux.org/index.php/Systemd/Journal#Journal_size_limit) - Keep only 512MB of logs
    * Systemd service timeout changed from 90 seconds to 45 seconds
- Password changes (How the password is stored):
    * [Increased hashing rounds](https://wiki.archlinux.org/title/SHA_password_hashes)
    * 4 second delay between password attempts
- Sudo changes:
    * [Prevent password timeout](https://wiki.archlinux.org/index.php/Sudo#Disable_password_prompt_timeout) when running long commands
    * [visudo editor](https://wiki.archlinux.org/index.php/Sudo#Using_visudo) changed from vi to nano
    * Commented line to run specific commands without requiring sudo password
    * Allow multiple TTYs to run sudo after one TTY has successfully ran sudo
    * Log file of elevated commands at /var/log/sudo.log
    * Five password tries instead of three
    * Password displayed with * instead of invisible
- NetworkManager changes:
    * [Random wireless MAC address](https://wiki.archlinux.org/index.php/NetworkManager#Configuring_MAC_address_randomization)
    * [IPv6 privacy extensions](https://wiki.archlinux.org/index.php/NetworkManager#Enable_IPv6_Privacy_Extensions)
    * [DNS caching](https://wiki.archlinux.org/index.php/NetworkManager#DNS_caching_and_conditional_forwarding) with dnsmasq
    * [Secure DNS servers](https://wiki.archlinux.org/index.php/NetworkManager#Setting_custom_global_DNS_servers) (1.1.1.1, 1.0.0.1, 9.9.9.9)
- [Aurmageddon](https://wailord284.club/) repository maintained by me. Contains 1500+ packages updated every 6 hours
    * [View the public repository here](https://wailord284.club/repo/aurmageddon/x86_64/)

# Things to consider when using this installer
- NO automatic updates or GUI package manager. You are expected to update the system regularly!
- NO manual partitioning (you can only select the drive)
- NO default folders generated in the user home directory (such as Desktop, Downloads, Documents, Pictures, Music....)
- NO Snapshots or backup system enabled even if BTRFS is selected
- Third party repositories enabled by default (archlinuxcn, chaotic-aur, aurmageddon)
- A significant amount of changes that may or may not align with the Arch Wiki or its suggestions
- Some aspects are optimized for performance/convenience over security
    * If your system has 2GB+ of RAM, additional utilities will be installed which will use additional RAM to increase performance
- Proprietary NVidia drivers are not configured. Only xf86-video-nouveau is installed
- Some of the UEFI tools will only work on systems with a newer UEFI implementation

# Todos
 - https://wiki.archlinux.org/title/Profile-sync-daemon
 - xsuspender?
 - x86 V3 support
    * /lib/ld-linux-x86-64.so.2 --help | grep supported
 - Combine filesystem setup
 - fix TTY ip address
 - optionally allow people to upload hw-probe
 - optionally allow people to upload pkgstats
