# Alex's Arch Linux Installer
A script to install a highly tuned Arch Linux desktop with XFCE, custom repositories, better performance and many Arch Wiki configurations with easy to use dialog prompts.

# How to use
To use this script, you first need to [create a bootable USB](https://www.howtogeek.com/howto/linux/create-a-bootable-ubuntu-usb-flash-drive-the-easy-way/) with the [Arch Linux ISO.](https://archlinux.org/download/) It is recommended to use the latest available version of the ISO. Once the ISO is booted and connected to the internet (which is required), you can download the script either from github or my website using curl. Both options will be kept up to date.
To use the script, do the following:
```
curl https://wailord284.club/repo/install.sh -o install.sh
bash install.sh
```
The user will now be prompted to supply basic information such as hostname, username, password, timezone, disk to install to, etc... Make sure to press space before pressing enter on options that require selecting something from a list.
# Features!
- Works with both UEFI and Legacy BIOS
- Automatic detection for Intel and AMD graphics
- Install guest additions for VirtualBox, QEMU/KVM or VMware if detected
- XFCE configured and themed with whiskermenu
- Support for [EXT4](https://wiki.archlinux.org/index.php/Ext4), [XFS](https://wiki.archlinux.org/index.php/XFS), [F2FS](https://wiki.archlinux.org/title/F2FS) or [BTRFS](https://wiki.archlinux.org/index.php/Btrfs) filesystems
    * EXT4 will use the [fast_commit](https://wiki.archlinux.org/title/Ext4#Enabling_fast_commit_in_existing_filesystems) option
    * F2FS will use [ZSTD level 6 compression](https://wiki.archlinux.org/title/F2FS#Compression) and compress checksums
    * BTRFS will use [zstd (level 3) and force compression](https://wiki.archlinux.org/index.php/Btrfs#Compression)
    * BTRFS scrub timer (monthly) will be enabled for the root directory
    * BTRFS snapshots with [Snapper](https://wiki.archlinux.org/title/Snapper) and [snap-pac](https://github.com/wesbarnett/snap-pac)
    * [Disable FSCK](https://wiki.archlinux.org/title/Improving_performance/Boot_process#Filesystem_mounts) mkinitcpio hook since it's not needed for BTRFS
    * All filesystems will use an *atime (usually noatime) mount option
- Optional setting to enable [disk encryption](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system) for the root partition
- Optional setting to [disable mitigations](https://wiki.archlinux.org/title/Improving_performance#Turn_off_CPU_exploit_mitigations) and enable [silent boot](https://wiki.archlinux.org/title/Silent_boot)
- Change mkinitcpio base and udev hooks to [systemd hook](https://wiki.archlinux.org/title/Improving_performance/Boot_process#Using_systemd_instead_of_busybox_on_early_init) to decrease boot time
- GPG keyserver for Pacman changed to [keyserver.ubuntu.com](https://keyserver.ubuntu.com/) and [pgp.mit.edu](https://pgp.mit.edu/)
- Nano [syntax highlighting](https://github.com/scopatz/nanorc), line numbers and position log enabled
- Preconfigured GPU accelerated terminal [Kitty](https://sw.kovidgoyal.net/kitty/)
- Automatic detection for Intel and AMD CPUs to [install correct microcode](https://wiki.archlinux.org/index.php/Microcode#Installation)
- Support for [Wacom touchscreen devices](https://wiki.archlinux.org/title/Graphics_tablet#Through_Xorg.conf) (like the Thinkpad X201T/X220T)
- Disabled ["Recents"](https://alexcabal.com/disabling-gnomes-recently-used-file-list-the-better-way) tab found in most file managers
- Large amount of [sysctl configs](https://wiki.archlinux.org/index.php/Sysctl#Improving_performance) gathered from the Arch wiki to increase performance and stability
- Automatic log rotation with [logrotate](https://wiki.archlinux.org/title/Logrotate)
- [lz4 mkinitcpio compression](https://wiki.archlinux.org/index.php/Mkinitcpio#COMPRESSION) to decrease compression and boot times
- [Greetd](https://wiki.archlinux.org/title/Greetd) display manager with optional autologin
- [Archlinuxcn](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#archlinuxcn) and [chaotic-aur](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#chaotic-aur) repositories for additional software
- [Earlyoom](https://github.com/rfjakob/earlyoom) daemon to trigger the Linux OOM killer sooner
- [FSTrim timer](https://wiki.archlinux.org/index.php/Solid_state_drive#Periodic_TRIM) to trim all SSDs weekly
- [Zram](https://aur.archlinux.org/packages/zramswap/) instead of swap (sets to 10% of total ram)
- [Modified IO Schedulers](https://wiki.archlinux.org/index.php/Improving_performance#Changing_I/O_scheduler) for hard drives, SATA SSDs and NVME drives
- [DBus-Broker](https://wiki.archlinux.org/index.php/D-Bus#dbus-broker) over traditional D-Bus for higher performance and reliability
- [Realtime priority](https://wiki.archlinux.org/index.php/Gaming#Enabling_realtime_priority_and_negative_nice_level) in Pulseaudio
- [Spindown hard drives after 20 minutes](https://wiki.archlinux.org/index.php/Hdparm#Power_management_configuration) using hdparm in udev
- [b43-firmware](https://wireless.wiki.kernel.org/en/users/drivers/b43/firmware) and [sof-firmware](https://github.com/thesofproject/sof-bin/) installed if required for device
- [Systemd-timesyncd](https://wiki.archlinux.org/title/Systemd-timesyncd) for system time
- [IRQBalance](https://irqbalance.github.io/irqbalance/) - An attempt to better balance system latency and throughput on multi-core systems
- [Reflector](https://wiki.archlinux.org/title/Reflector#systemd_timer) timer enabled to sort mirrors weekly
- [Enforce Stronger SSH encryption](https://www.sshaudit.com/hardening_guides.html) - Configure .ssh/config to use strong ciphers by default
- [5 second delay between password attempts](https://wiki.archlinux.org/title/Security#Enforce_a_delay_after_a_failed_login_attempt)
- Changes if RAM is over 2GB
    * [Preload](https://wiki.archlinux.org/index.php/Preload#Preload) - Daemon to load commonly used applications/files in RAM to speed up the system
    * [Profile-sync-daemon](https://wiki.archlinux.org/index.php/Profile-sync-daemon) - Copy browser profiles into RAM and sync to disk ever 30 minutes
- Firefox changes:
    * [Ublock Origin](https://ublockorigin.com/) - Ad blocker
    * [Decentral Eyes](https://decentraleyes.org/) - Local emulation of Content Delivery Networks
    * A privacy oriented prefs.js focused on compatibility made with [ffprofile](https://ffprofile.com/)
    * A custom user.js with changes based on [BetterFox](https://github.com/yokoffing/Betterfox)
- Polkit changes:
    * [Libvirt](https://wiki.archlinux.org/title/Libvirt#Using_polkit) - Use libvirt without password (users in the kvm group)
    * [NetworkManager](https://wiki.archlinux.org/title/NetworkManager#Set_up_PolicyKit_permissions) - Add/Remove a network without a password (users in the network group)
    * [GParted](https://wiki.archlinux.org/title/Polkit#Authorization_rules) - Allow gparted to run without a password (users in disk group)
    * [Gsmartcontrol](https://gsmartcontrol.sourceforge.io/home/) - Allows gsmartcontrol to run without a password (users in disk group)
    * [BTRFS Assistant](https://gitlab.com/btrfs-assistant/btrfs-assistant) - Allows btrfs-assistant to run without a password (users in disk group)
- Bash changes:
    * [.inputrc](https://wiki.archlinux.org/index.php/Readline#Faster_completion) - Add color and improve tab completion
    * [ASCII Pokemon](https://gitlab.com/phoneybadger/pokemon-colorscripts) - Display a pokemon in terminal
    * Add colored output to ls, ip, grep and file extensions
    * Custom aliases for trizen, pacman and other system tasks
- Laptop changes (If detected):
    * [Tackpad](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/70-synaptics.conf) - More comfortable defaults
    * [TLP](https://wiki.archlinux.org/title/TLP) - Default settings and PCIE_ASPM_ON_BAT=powersupersave
- Grub changes:
    * [File Manager](https://github.com/a1ive/grub2-filemanager), Reboot and Shutdown - Available as additional grub menus
    * [UEFI tools:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/tools) [UEFI Shell](https://github.com/pbatard/UEFI-Shell), [Memtest86](https://memtest.org/), [Super Grub Disk 2](https://www.supergrubdisk.org/)
    * [UEFI games:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/games) [Tetris](https://github.com/a1ive/uefi-tetris/), [Flappybird](https://github.com/hymen81/UEFI-Game-FlappyBirdy)
    * Arch Linux [theme](https://github.com/fghibellini/arch-silence)
- Pacman changes:
    * [Kernel Modules hook](https://github.com/saber-nyan/kernel-modules-hook) - Restore functionality when the running kernel updates
    * [Needrestart hook](https://github.com/liske/needrestart) - Restart outdated libraries
    * Package cleanup hook to minimize the pacman cache size when updating
    * Update and reinstall grub hook after grub updates
    * Verbose Package changes, Color, Parallel downloads
- Makepkg changes:
    * Set makeflags to use all cores when compiling
    * Change -mtune=generic to [native](https://wiki.archlinux.org/index.php/Makepkg#Building_optimized_binaries)
    * Change RUSTFLAGS to build [native](https://wiki.archlinux.org/index.php/Makepkg#Building_optimized_binaries) binaries
    * Use [.tar](https://wiki.archlinux.org/index.php/Makepkg#Use_other_compression_algorithms) as default package extension (no compression) when building AUR packages
    * [Multithreaded](https://wiki.archlinux.org/index.php/Makepkg#Parallel_compilation) capable compression programs for supported files
    * [Max compression](https://wiki.archlinux.org/title/Makepkg#Utilizing_multiple_cores_on_compression) when compressing .xz and .zst (If package extension changed to .pkg.tar.xz or .zst)
    * LTO optimizations enabled
- Systemd changes:
    * [Journal log always visible](https://wiki.archlinux.org/index.php/Systemd/Journal#Forward_journald_to_/dev/tty12) on tty12 (control + alt + F12)
    * [Keep only 1024MB](https://wiki.archlinux.org/index.php/Systemd/Journal#Journal_size_limit) of Journald logs and compress them
    * [Display network interface IP Addresses](https://github.com/wailord284/Alexs-Arch-Installer/blob/master/configs/scripts/ttyinterfaces.sh) on TTY logins - Systemd service and script (disabled by default)
    * Systemd service timeout changed from 90 seconds to 45 seconds
    * Disable coredump in coredump.conf
- Sudo changes:
    * [Prevent password timeout](https://wiki.archlinux.org/index.php/Sudo#Disable_password_prompt_timeout) when running long commands
    * [visudo editor](https://wiki.archlinux.org/index.php/Sudo#Using_visudo) changed from vi to nano
    * Users must be in the [wheel group to run su](https://wiki.archlinux.org/title/Su#su_and_wheel)
    * Disable [Systemd-homed not available](https://www.reddit.com/r/archlinux/comments/ie3cvj/pam_systemd_home_spamming_the_journal_everytime_i/) log message everytime sudo is run
    * Reboot and poweroff do not requrie the sudo password to run
    * Allow multiple TTYs to run sudo after one TTY has successfully ran sudo
    * Password displayed with * instead of being invisible
- NetworkManager changes:
    * [Random wireless MAC address](https://wiki.archlinux.org/index.php/NetworkManager#Configuring_MAC_address_randomization)
    * [IPv6 privacy extensions](https://wiki.archlinux.org/title/IPv6#NetworkManager)
    * [Faster default DNS servers](https://wiki.archlinux.org/index.php/NetworkManager#Setting_custom_global_DNS_servers) - [Cloudflare 1.1.1.1](https://1.1.1.1/)
    * [Disable systemd-resolve](https://wiki.archlinux.org/title/NetworkManager#Unit_dbus-org.freedesktop.resolve1.service_not_found) to remove "unit dbus-org.freedesktop.resolve1.service not found" in journal log
- [Aurmageddon](https://wailord284.club/) repository maintained by me. Contains ~1000 packages
    * [View the public repository here](https://wailord284.club/repo/aurmageddon/x86_64/)

# Things to consider when using this installer
- NO automatic updates or GUI package manager. You are expected to update the system regularly!
- NO manual partitioning (you can only select the drive) or dual booting
- Third party repositories enabled by default (archlinuxcn, chaotic-aur, aurmageddon)
- A significant amount of changes that may or may not align with the Arch Wiki or its suggestions
- Some aspects are optimized for performance/convenience over security
    * If your system has 2GB+ of RAM, additional utilities will be installed which will use additional RAM to increase performance
- Proprietary NVidia drivers are not configured. Only xf86-video-nouveau is installed
- Some of the UEFI tools will only work on systems with a newer UEFI implementation

# Todos
 - Finish working on implementing dialog prompts as functions
 - optionally allow people to upload hw-probe
 - optionally allow people to upload pkgstats
