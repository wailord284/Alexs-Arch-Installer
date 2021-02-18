# Alex's Arch Linux Installer
A simple script to automatically install Arch Linux with the XFCE desktop, custom repository and many post install options.

# About
This is a small script I have been working on for over a year to simplify the Arch Linux install process across the many different types of hardware I have. The goal of this script is to install Arch with a useable experience right out of the box while still maintaining a mostly vanilla setup. Since I use my devices for many different things, I have tried to support many different configurations and optional configs/utilities a user may want. Once the script completes the user can implement 20+ optional features that may be beneficial to them.

# How to use
To use this script, you first need to [create a bootable USB](https://www.howtogeek.com/howto/linux/create-a-bootable-ubuntu-usb-flash-drive-the-easy-way/) with the [Arch Linux ISO.](https://archlinux.org/download/) Once the ISO is booted and connected to the internet (which is required), you can download the script either from github or my website using curl. Both options will be kept up to date. Make sure you run the script using bash, otherwise zsh will interpret the script and error.
To use the script, do the following:
```
curl https://wailord284.club/repo/install.sh -o install.sh
chmod +x install.sh
./install.sh
```
The user will now be prompted to supply basic information such as hostname, username, password, timezone, disk to install to, disk encryption and full disk wipe. Each option has a "default" which can be used by pressing enter without entering any text. Make sure to press space before pressing enter on options that require selecting something from a list.
# Features!
- Works with both UEFI [(64 and 32 bit)](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L292) and BIOS!
- Automatic detection for Intel, AMD and NVidia graphics
- Automatic detection for Intel and AMD CPUs [Installs correct microcode](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L448)
- Automatically detect if running in VirtualBox, KVM or VMware and [install appropriate guest additions](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L669)
- Optionally overwrite the drive with random data [Secure erase](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L270)
- Optional [disk encryption](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L321) for the main root partition (SHA512, Luks2, 3 second iteration time)
- [Earlyoom](https://github.com/rfjakob/earlyoom) daemon to trigger the Linux OOM killer sooner
- [Kernel Modules hook](https://github.com/saber-nyan/kernel-modules-hook) to restore functionality when the running kernel updates
- [Pacman cleanup hook](https://aur.archlinux.org/packages/pacman-cleanup-hook/) to minimize the pacman cache size when updating
- [FSTrim timer](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L573) if a SSD is detected
- [Zram](https://aur.archlinux.org/packages/zramswap/) instead of swap (sets to 20% of total ram using zramswap)
- [Modified IO Schedulers](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/udev/60-ioschedulers.rules) for hard drives, SSDs and NVME drives
- Change [mkinitcpio compression to ZSTD](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L465) (Added in kernel 5.9)
- [Custom nanorc](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L616) file to include syntax highlighting
- Support for [Touchscreen devices](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/72-wacom-options.conf) (such as the Thinkpad X201T/X220T)
- Modified freetype2 and fonts/local.conf to [improve font rendering](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/fonts/local.conf) (default font: Ubuntu)
- Slightly modified XFCE configuration to enable compositing, change font and change theme
- Disabled ["Recents"](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/gtk-3.0/settings.ini) found in most file managers
- LXDM display manager with [Archlinux theme](https://aur.archlinux.org/packages/archlinux-lxdm-theme/)
- Large amount of [sysctl.d/ configs](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/sysctl) gathered from the Arch wiki to increase performance and stability
- Xorg keybind [(Control + Alt + Backspace)](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/90-zap.conf) to return to login screen
- Add the [Archlinuxcn](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#archlinuxcn) and [chaotic-aur](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#chaotic-aur) repository for additional software
- [DBus-Broker](https://wiki.archlinux.org/index.php/D-Bus#dbus-broker) over traditional D-Bus for higher performance and reliability
- Bash changes:
    * Custom [.inputrc](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/bash/.inputrc) to add color and improve tab completion
    * Add colored output to ls (installed ls-colors-git)
    * Custom aliases for yay/pacman and other system tasks
    * [ASCII Pokemon](https://aur.archlinux.org/packages/pokeshell/) on terminal startup
- Laptop Changes (If detected):
    * Modified [trackpad behavior](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/70-synaptics.conf) to be more comfortable
    * Implement USB and hard drive [power saving features](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L765) like TLP
- Grub changes:
    * [Disabled spectre/meltdown patches](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L900) (Increase performance. Edit /etc/defult/grub to remove)
    * Trust CPU Random Number Generation (random.trust_cpu=on) improves boot time
    * Arch Linux theme
    * Reboot, shutdown, [File Manager](https://github.com/a1ive/grub2-filemanager) option for both UEFI/BIOS
    * UEFI Only [tools:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/tools) UEFI Shell, GDisk partition editor, Chipset reader
    * UEFI Only [games:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/games) Tetris, Flappybird
    * Please note some UEFI tools will only work if the UEFI is newer (UEFI shell v1 works on all systems)
- Makepkg changes:
    * Change makeflags to account for [all cores](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L648) in the system (-j)
    * Change -mtune=generic to [native](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L649)
    * Use [.tar](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L654) as default package extension (No compression) when building AUR packages
    * Add [multithreaded](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L650) capable compression programs for supported files
    * Enable max compression when compressing [.xz](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L652) and [.zst](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L653) (If package extension changed to .pkg.tar.xz or .zst)
- Systemd changes:
    * Systemd service timeout changed from [90 seconds to 45 seconds](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L640)
    * [Promiscuous mode](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/systemd/promiscuous%40.service) systemd service to make packet sniffing easier (disabled by default)
    * [Journal log always visible](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/systemd/fw-tty12.conf) on tty12 (control + alt + F12)
    * Keep only [512MB of journald logs](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/systemd/00-journal-size.conf) (/var/log/journal)
- Password changes (How the password is stored):
    * Increase hashing rounds and change hash to [SHA512](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L505)
    * [4 second delay](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L514) between password attempts
- Sudo changes:
    * [Prevent password timeout](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L635) when running long commands
    * Allow [multiple TTYs to run sudo](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L634) after one TTY has successfully ran sudo
    * [visudo editor](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L636) changed from vi to nano
    * Commented line to run specific commands [without requiring sudo password](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L637)
- Modified NetworkManager setup:
    * [Random wireless MAC address](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/networkmanager/rand_mac.conf)
    * Increased [IPv6 privacy](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L738)
    * [DNS cacheing](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/networkmanager/dns.conf) with dnsmasq (currently disabled)
    * [Secure DNS servers](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/networkmanager/dns-servers.conf) (1.1.1.1, 1.0.0.1, 9.9.9.9) (replaced by dnscrypt and dnsmasq if selected)
    * Automatic hardware clock updates using [NTP](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/networkmanager/hwclock.conf) (Updates everytime device connects to internet)
- [Aurmageddon](https://wailord284.club/) repository maintained by me. Contains 1500+ packages updated every 6 hours.
    * Packages installed from Aurmageddon include:
    * ```surfn-icons-git pokeshell arch-silence-grub-theme-git archlinux-lxdm-theme-full bibata-cursor-translucent usbimager kernel-modules-hook matcha-gtk-theme-git nordic-theme-git pacman-cleanup-hook ttf-unifont materiav2-gtk-theme layan-gtk-theme-git lscolors-git zramswap```
    * [View the public repository here](https://wailord284.club/repo/aurmageddon/x86_64/)
- Post Install Options (All optional)
    * Once the installation is complete the user will be prompted with optional settings/configs
    * Convert to [Bedrock Linux](https://bedrocklinux.org/) (Not reversible)
    * [X2Go](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L962) remote management server
    * Enable [SSHD](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L971)
    * Route [all network traffic over Tor](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L977) (Not reversible)
    * Sort mirrors with [Reflector](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L999) (Recommended)
    * Enable and install the [UFW firewall](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1008)
    * Use the [IWD wifi backend](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1019) instead of wpa_supplicant for NetworkManager
    * Restore [traditional network interface names](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1026) (eth0, wlan0...)
    * [Disable/Blacklist](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1032) bluetooth and webcam
    * Enable [Firejail](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1042) for all supported applications
    * Enable [VNstat webui](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1055) traffic monitor
    * Enable local [Searx](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1074) search engine
    * Install [PlatformIO](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1082) Udev rules for Arduino Communication
    * Enable [AMD Freesync](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1089)
    * Enable [automatic desktop login](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1097) with LXDM (Recommended)
    * Enable daily [rootkit detection scan with rkhunter](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1103)
    * Enable [Ananicy](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1113) - Daemon for setting CPU priority and scheduling
    * [Block ads](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1121) system wide using Hblock to modify the hosts file (Recommended)
    * [Encrypt and cache DNS requests](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L1130) - Enables DNSCrypt and DNSMasq

### Todos
 - Move user configs to /etc/skel so new users can get same config setup
 - https://kernelnewbies.org/Linux_5.10#Ext4_fast_commit_support.2C_for_faster_metadata_performance look into this for ext4 performance
