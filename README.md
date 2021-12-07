# Alex's Arch Linux Installer
A simple script to automatically install a highly tuned (under the hood) Arch Linux with the XFCE desktop, custom repositories, better performance and many post install options. Add me on Discord for any thoughts/comments/concerns/issues: wailord284#3794

# How to use
To use this script, you first need to [create a bootable USB](https://www.howtogeek.com/howto/linux/create-a-bootable-ubuntu-usb-flash-drive-the-easy-way/) with the [Arch Linux ISO.](https://archlinux.org/download/) It is recommended to use the latest availible version of the ISO. Once the ISO is booted and connected to the internet (which is required), you can download the script either from github or my website using curl. Both options will be kept up to date. Make sure you run the script using bash, otherwise zsh will interpret the script and error.
To use the script, do the following:
```
curl https://wailord284.club/repo/install.sh -o install.sh
bash install.sh
```
The user will now be prompted to supply basic information such as hostname, username, password, timezone, disk to install to, disk encryption and full disk wipe. Each option has a "default" which can be used by pressing enter without entering any text. Make sure to press space before pressing enter on options that require selecting something from a list.
# Features! (in no particular order)
- Works with both UEFI (64 and 32 bit) and BIOS!
- Automatic detection for Intel, AMD and NVidia graphics
- Automatically detect if running in VirtualBox, KVM or VMware and install appropriate guest additions
- Optional disk encryption for the main root partition (SHA512, Luks2, 3 second iteration time)
- Slightly modified XFCE configuration to enable compositing, change font and change theme
- Custom nanorc file to include syntax highlighting
- Optionally install custom kernels (linux-tkg) with GCC CPU optimizations from chaotic-aur
- Display all network interfaces IP Addresses on TTY logins
- Support for [EXT4](https://wiki.archlinux.org/index.php/Ext4), [XFS](https://wiki.archlinux.org/index.php/XFS), [JFS](https://wiki.archlinux.org/title/JFS), [NILFS2](https://en.wikipedia.org/wiki/NILFS), [F2FS](https://wiki.archlinux.org/title/F2FS) or [BTRFS](https://wiki.archlinux.org/index.php/Btrfs) filesystems
    * BTRFS will use [compress=zstd](https://wiki.archlinux.org/index.php/Btrfs#Compression) for default compression. Edit /etc/fstab to change to LZO or ZLIB
    * BTRFS scrub timer will be enabled for the root directory if selected
    * All filesystems will use an *atime (noatime or lazytime usually) mount option
- GPG keyserver for Pacman changed to [keyserver.ubuntu.com](https://keyserver.ubuntu.com/)
- Preconfigured GPU Accelerated terminal [Kitty](https://sw.kovidgoyal.net/kitty/)
- Automatic detection for Intel and AMD CPUs to [install correct microcode](https://wiki.archlinux.org/index.php/Microcode#Installation)
- Optionally overwrite the drive with random data to [securely erase](https://wiki.archlinux.org/index.php/Securely_wipe_disk#shred) the drive
- [Earlyoom](https://github.com/rfjakob/earlyoom) daemon to trigger the Linux OOM killer sooner
- [Kernel Modules hook](https://github.com/saber-nyan/kernel-modules-hook) to restore functionality when the running kernel updates
- [Pacman cleanup hook](https://aur.archlinux.org/packages/pacman-cleanup-hook/) to minimize the pacman cache size when updating
- [FSTrim timer](https://wiki.archlinux.org/index.php/Solid_state_drive#Periodic_TRIM) if a SSD is detected
- [Zram](https://aur.archlinux.org/packages/zramswap/) instead of swap (sets to 20% of total ram using zramswap)
- [Modified IO Schedulers](https://wiki.archlinux.org/index.php/Improving_performance#Changing_I/O_scheduler) for hard drives, SSDs and NVME drives
- Change [mkinitcpio compression to ZSTD](https://wiki.archlinux.org/index.php/Mkinitcpio#COMPRESSION) (Added in kernel 5.9)
- Support for [Touchscreen devices](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/72-wacom-options.conf) (such as the Thinkpad X201T/X220T)
- Disabled ["Recents"](https://alexcabal.com/disabling-gnomes-recently-used-file-list-the-better-way) found in most file managers
- LXDM display manager with [Archlinux theme](https://aur.archlinux.org/packages/archlinux-lxdm-theme/)
- Large amount of [sysctl.d/configs](https://wiki.archlinux.org/index.php/Sysctl#Improving_performance) gathered from the Arch wiki to increase performance and stability
- Xorg keybind [(Control + Alt + Backspace)](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/90-zap.conf) to return to login screen
- Add the [Archlinuxcn](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#archlinuxcn) and [chaotic-aur](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#chaotic-aur) repository for additional software
- Automatic log rotation with [logrotate](https://wiki.archlinux.org/title/Logrotate)
- [DBus-Broker](https://wiki.archlinux.org/index.php/D-Bus#dbus-broker) over traditional D-Bus for higher performance and reliability
- [Realtime priority](https://wiki.archlinux.org/index.php/Gaming#Enabling_realtime_priority_and_negative_nice_level) in Pulseaudio
- [Spindown hard drives after 20 minutes](https://wiki.archlinux.org/index.php/Hdparm#Power_management_configuration) using hdparm in udev
- [Zlib-ng](https://github.com/zlib-ng/zlib-ng) with modern features and optimizations compared to zlib
- [b43-firmware](https://wireless.wiki.kernel.org/en/users/drivers/b43/firmware) installed if missing wireless card firmware
- [Prelockd](https://github.com/hakavlad/prelockd) daemon to lock desktop in RAM if system ram is detected over 2GB
- [Preload](https://wiki.archlinux.org/index.php/Preload#Preload) daemon to load commonly used applications/files in RAM to speed up the system if system ram is detected over 2GB
- [Ananicy-cpp](https://gitlab.com/ananicy-cpp/ananicy-cpp) daemon to automatically set the NICe value of programs if system ram is detected over 2GB
    * [Ananicy rules](https://aur.archlinux.org/packages/ananicy-rules-git/) are also installed for extra program support
    * Ananicy-cpp was chosen for its better performance and lower RAM usage over the original ananicy
    * Check frequency was also changed from 5 to 15 seconds
- Firefox changes (All installed with package manager):
    * [Ublock Origin](https://ublockorigin.com/) - Ad blocker
    * [Canvas Blocker](https://addons.mozilla.org/en-US/firefox/addon/canvasblocker/) - Jacascript blocker
    * [ClearURLs](https://addons.mozilla.org/en-US/firefox/addon/clearurls/) - URL Tracker blocker
    * [User Agent Switcher](https://addons.mozilla.org/en-US/firefox/addon/uaswitcher/?utm_source=gitlab) - Change browser user agent randomly
    * [LocalCDN](https://addons.mozilla.org/en-US/firefox/addon/localcdn-fork-of-decentraleyes/) - Local emulation of Content Delivery Networks
- Polkit changes:
    * [Libvirt rule](https://wiki.archlinux.org/title/Libvirt#Using_polkit) to use libvirt without password (users in the KVM group)
    * [NetworkManager rule](https://wiki.archlinux.org/title/NetworkManager#Set_up_PolicyKit_permissions) to add/remove a network without a password (users in the network group)
    * [GParted rule](https://wiki.archlinux.org/title/Polkit#Authorization_rules) to allow gparted to run without a password (users in storage group)
    * [Gsmartcontrol](https://gsmartcontrol.sourceforge.io/home/) rule allowing gsmartcontrol to run without a password (users in storage group)
- Bash changes:
    * Custom [.inputrc](https://wiki.archlinux.org/index.php/Readline#Faster_completion) to add color and improve tab completion
    * [ASCII Pokemon](https://aur.archlinux.org/packages/pokeshell/) on terminal startup
    * Add colored output to ls (installed ls-colors-git)
    * Custom aliases for yay/pacman and other system tasks
- Laptop changes (If detected):
    * Modified [trackpad behavior](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/70-synaptics.conf) to be more comfortable
    * [TLP](https://wiki.archlinux.org/title/TLP) with default settings
    * [Powertop](https://wiki.archlinux.org/title/Powertop) with --auto-tune enabled
- Grub changes:
    * [Disabled spectre/meltdown patches](https://make-linux-fast-again.com/) (Increase performance. Edit /etc/defult/grub to remove)
    * Reboot, shutdown, [File Manager](https://github.com/a1ive/grub2-filemanager) option for both UEFI/BIOS
    * UEFI Only [tools:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/tools) UEFI Shell, GDisk partition editor
    * UEFI Only [games:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/games) Tetris, Flappybird
    * Trust CPU Random Number Generation (random.trust_cpu=on) improves boot time
    * Arch Linux theme
    * Please note some UEFI tools will only work if the UEFI is newer (UEFI shell v1 should work on all systems)
- Makepkg changes:
    * Change makeflags to account for [all cores](https://wiki.archlinux.org/index.php/Makepkg#Building_optimized_binaries) in the system (-j)
    * Change -mtune=generic to [native](https://wiki.archlinux.org/index.php/Makepkg#Building_optimized_binaries)
    * Change RUSTFLAGS to build [native](https://wiki.archlinux.org/index.php/Makepkg#Building_optimized_binaries) binaries
    * Use [.tar](https://wiki.archlinux.org/index.php/Makepkg#Use_other_compression_algorithms) as default package extension (No compression) when building AUR packages
    * Add [multithreaded](https://wiki.archlinux.org/index.php/Makepkg#Parallel_compilation) capable compression programs for supported files
    * Enable max compression when compressing .xz and .zst (If package extension changed to .pkg.tar.xz or .zst)
    * LTO optimizations enabled
- Systemd changes:
    * [Promiscuous mode](https://wiki.archlinux.org/index.php/Network_configuration#Promiscuous_mode) systemd service to make packet sniffing easier (disabled by default)
    * [Journal log always visible](https://wiki.archlinux.org/index.php/Systemd/Journal#Forward_journald_to_/dev/tty12) on tty12 (control + alt + F12)
    * Keep only [512MB of journald logs](https://wiki.archlinux.org/index.php/Systemd/Journal#Journal_size_limit) (/var/log/journal)
    * Systemd service timeout changed from 90 seconds to 45 seconds
- Password changes (How the password is stored):
    * Increase hashing rounds and change hash to [SHA512](https://wiki.archlinux.org/title/SHA_password_hashes)
    * 4 second delay between password attempts
- Sudo changes:
    * [Prevent password timeout](https://wiki.archlinux.org/index.php/Sudo#Disable_password_prompt_timeout) when running long commands
    * [visudo editor](https://wiki.archlinux.org/index.php/Sudo#Using_visudo) changed from vi to nano
    * Commented line to run specific commands without requiring sudo password
    * Allow multiple TTYs to run sudo after one TTY has successfully ran sudo
    * Log file of elevated commands at /var/log/sudo.log
    * Five password tries instead of 3
    * Password displayed with * instead of invisible
- NetworkManager changes:
    * [Random wireless MAC address](https://wiki.archlinux.org/index.php/NetworkManager#Configuring_MAC_address_randomization)
    * [IPv6 privacy extensions](https://wiki.archlinux.org/index.php/NetworkManager#Enable_IPv6_Privacy_Extensions)
    * [DNS caching](https://wiki.archlinux.org/index.php/NetworkManager#DNS_caching_and_conditional_forwarding) with dnsmasq
    * [Secure DNS servers](https://wiki.archlinux.org/index.php/NetworkManager#Setting_custom_global_DNS_servers) (1.1.1.1, 1.0.0.1, 9.9.9.9) (replaced by dnscrypt and dnsmasq if selected)
    * Automatic hardware clock updates using [NTP](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/networkmanager/hwclock.conf) (Updates everytime device connects to internet)
- [Aurmageddon](https://wailord284.club/) repository maintained by me. Contains 1500+ packages updated every 6 hours.
    * [View the public repository here](https://wailord284.club/repo/aurmageddon/x86_64/)

# Things to consider when using this installer
- NO Automatic updates. You are expected to update the system regularly!
- NO manual partitioning (you can only select the drive)
- NO default folders generated in the user home directory (such as Desktop, Downloads, Documents, Pictures, Music....)
- NO Snapshots or backup system enabled even if BTRFS is selected
- Spectre and Meltdown mitigations are disabled!
    * noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off mitigations=off
- Third party repositories enabled by default (archlinuxcn, chaotic-aur, aurmageddon)
- A significant amount of changes that may or may not align with the Arch Wiki or its suggestions

# Todos
 - Combine filesystem setup
 - fix TTY ip address
 - investigate dialog functions and rename height/width variables
 - optionally allow people to upload hw-probe
 - optionally allow people to upload pkgstats
