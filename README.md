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
# Features! (in no particular order)
- Works with both UEFI (64 and 32 bit) and BIOS!
- Automatic detection for Intel, AMD and NVidia graphics
- Automatically detect if running in VirtualBox, KVM or VMware and install appropriate guest additions
- Optional disk encryption for the main root partition (SHA512, Luks2, 3 second iteration time)
- Slightly modified XFCE configuration to enable compositing, change font and change theme
- Custom nanorc file to include syntax highlighting
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
- Modified freetype2 and fonts/local.conf to [improve font rendering](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/fonts/local.conf) (default font: Ubuntu)
- Disabled ["Recents"](https://alexcabal.com/disabling-gnomes-recently-used-file-list-the-better-way) found in most file managers
- LXDM display manager with [Archlinux theme](https://aur.archlinux.org/packages/archlinux-lxdm-theme/)
- Large amount of [sysctl.d/configs](https://wiki.archlinux.org/index.php/Sysctl#Improving_performance) gathered from the Arch wiki to increase performance and stability
- Xorg keybind [(Control + Alt + Backspace)](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/90-zap.conf) to return to login screen
- Add the [Archlinuxcn](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#archlinuxcn) and [chaotic-aur](https://wiki.archlinux.org/index.php/Unofficial_user_repositories#chaotic-aur) repository for additional software
- [DBus-Broker](https://wiki.archlinux.org/index.php/D-Bus#dbus-broker) over traditional D-Bus for higher performance and reliability
- [Realtime priority](https://wiki.archlinux.org/index.php/Gaming#Enabling_realtime_priority_and_negative_nice_level) in Pulseaudio
- [Prelockd](https://github.com/hakavlad/prelockd) daemon to lock desktop in RAM if system ram is detected over 2GB
- [Preload](https://wiki.archlinux.org/index.php/Preload#Preload) daemon to load commonly used applications/files in RAM to speed up the system if system ram is detected over 2GB
- Firefox changes (All installed with package manager):
    * [Ublock Origin](https://ublockorigin.com/) ad blocker
    * [Privacy Badger](https://privacybadger.org/)
    * [HTTPS Everywhere](https://www.eff.org/https-everywhere)
    * [Canvas Blocker](https://addons.mozilla.org/en-US/firefox/addon/canvasblocker/)
    * [ClearURLs](https://addons.mozilla.org/en-US/firefox/addon/clearurls/)
- Bash changes:
    * Custom [.inputrc](https://wiki.archlinux.org/index.php/Readline#Faster_completion) to add color and improve tab completion
    * [ASCII Pokemon](https://aur.archlinux.org/packages/pokeshell/) on terminal startup
    * Add colored output to ls (installed ls-colors-git)
    * Custom aliases for yay/pacman and other system tasks
- Laptop changes (If detected):
    * Modified [trackpad behavior](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/xorg/70-synaptics.conf) to be more comfortable
    * Implement USB and hard drive [power saving features](https://wiki.archlinux.org/index.php/Power_management#Power_saving) like TLP
- Grub changes:
    * [Disabled spectre/meltdown patches](https://make-linux-fast-again.com/) (Increase performance. Edit /etc/defult/grub to remove)
    * Reboot, shutdown, [File Manager](https://github.com/a1ive/grub2-filemanager) option for both UEFI/BIOS
    * UEFI Only [tools:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/tools) UEFI Shell, GDisk partition editor, Chipset reader
    * UEFI Only [games:](https://github.com/wailord284/Arch-Linux-Installer/tree/master/configs/grub/games) Tetris, Flappybird
    * Trust CPU Random Number Generation (random.trust_cpu=on) improves boot time
    * Arch Linux theme
    * Please note some UEFI tools will only work if the UEFI is newer (UEFI shell v1 works on all systems)
- Makepkg changes:
    * Change makeflags to account for [all cores](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L648) in the system (-j)
    * Change -mtune=generic to [native](https://wiki.archlinux.org/index.php/Makepkg#Building_optimized_binaries)
    * Use [.tar](https://wiki.archlinux.org/index.php/Makepkg#Use_other_compression_algorithms) as default package extension (No compression) when building AUR packages
    * Add [multithreaded](https://wiki.archlinux.org/index.php/Makepkg#Parallel_compilation) capable compression programs for supported files
    * Enable max compression when compressing .xz and .zst (If package extension changed to .pkg.tar.xz or .zst)
- Systemd changes:
    * [Promiscuous mode](https://wiki.archlinux.org/index.php/Network_configuration#Promiscuous_mode) systemd service to make packet sniffing easier (disabled by default)
    * [Journal log always visible](https://wiki.archlinux.org/index.php/Systemd/Journal#Forward_journald_to_/dev/tty12) on tty12 (control + alt + F12)
    * Keep only [512MB of journald logs](https://wiki.archlinux.org/index.php/Systemd/Journal#Journal_size_limit) (/var/log/journal)
    * Systemd service timeout changed from 90 seconds to 45 seconds
- Password changes (How the password is stored):
    * Increase hashing rounds and change hash to [SHA512](https://wiki.archlinux.org/index.php/Security#User_setup)
    * 4 second delay between password attempts
- Sudo changes:
    * [Prevent password timeout](https://wiki.archlinux.org/index.php/Sudo#Disable_password_prompt_timeout) when running long commands
    * [visudo editor](https://wiki.archlinux.org/index.php/Sudo#Using_visudo) changed from vi to nano
    * Commented line to run specific commands [without requiring sudo password](https://github.com/wailord284/Arch-Linux-Installer/blob/master/install.sh#L637)
    * Allow multiple TTYs to run sudo after one TTY has successfully ran sudo
- NetworkManager changes:
    * [Random wireless MAC address](https://wiki.archlinux.org/index.php/NetworkManager#Configuring_MAC_address_randomization)
    * [IPv6 privacy extensions](https://wiki.archlinux.org/index.php/NetworkManager#Enable_IPv6_Privacy_Extensions)
    * [DNS cacheing](https://wiki.archlinux.org/index.php/NetworkManager#DNS_caching_and_conditional_forwarding) with dnsmasq (currently disabled)
    * [Secure DNS servers](https://wiki.archlinux.org/index.php/NetworkManager#Setting_custom_global_DNS_servers) (1.1.1.1, 1.0.0.1, 9.9.9.9) (replaced by dnscrypt and dnsmasq if selected)
    * Automatic hardware clock updates using [NTP](https://github.com/wailord284/Arch-Linux-Installer/blob/master/configs/networkmanager/hwclock.conf) (Updates everytime device connects to internet)
- [Aurmageddon](https://wailord284.club/) repository maintained by me. Contains 1500+ packages updated every 6 hours.
    * [View the public repository here](https://wailord284.club/repo/aurmageddon/x86_64/)
    * Packages installed from Aurmageddon include:
    * ```surfn-icons-git pokeshell arch-silence-grub-theme-git archlinux-lxdm-theme-full bibata-cursor-translucent usbimager kernel-modules-hook matcha-gtk-theme-git nordic-theme-git pacman-cleanup-hook ttf-unifont materiav2-gtk-theme layan-gtk-theme-git lscolors-git zramswap prelockd preload firefox-clearurls firefox-extension-canvasblocker```
- Post Install Options (All optional)
    * Once the installation is complete the user will be prompted with optional settings/configs
    * Convert to [Bedrock Linux](https://bedrocklinux.org/) (Not reversible)
    * [X2Go](https://wiki.archlinux.org/index.php/X2Go#Server_side) remote management server
    * Enable [SSHD](https://wiki.archlinux.org/index.php/OpenSSH#Server_usage)
    * Route all network traffic over [Tor](https://wiki.archlinux.org/index.php/Tor) (Not reversible)
    * Sort mirrors with [Reflector](https://wiki.archlinux.org/index.php/Reflector) (Recommended)
    * Enable and install the [UFW firewall](https://wiki.archlinux.org/index.php/Uncomplicated_Firewall)
    * Use the [IWD wifi backend](https://wiki.archlinux.org/index.php/NetworkManager#Using_iwd_as_the_Wi-Fi_backend) instead of wpa_supplicant for NetworkManager
    * Restore [traditional network interface names](https://wiki.archlinux.org/index.php/Network_configuration#Revert_to_traditional_interface_names) (eth0, wlan0...)
    * Disable/Blacklist bluetooth and webcam
    * Enable [Firejail](https://wiki.archlinux.org/index.php/Firejail) for all supported applications
    * Enable [VNstat webui](https://www.tecmint.com/vnstat-php-frontend-for-monitoring-network-bandwidth/) traffic monitor
    * Enable local [Searx](https://github.com/searx/searx) search engine
    * Install [PlatformIO](https://docs.platformio.org/en/latest/faq.html#platformio-udev-rules) Udev rules for Arduino Communication
    * Enable [AMD Freesync](https://wiki.archlinux.org/index.php/Variable_refresh_rate)
    * Enable [automatic desktop login](https://wiki.archlinux.org/index.php/LXDM#Autologin) with LXDM (Recommended)
    * Enable daily [rootkit detection scan with rkhunter](https://donatoroque.wordpress.com/2017/08/13/setting-up-rkhunter-using-systemd/)
    * Enable [Ananicy](https://github.com/Nefelim4ag/Ananicy) - Daemon for setting CPU priority and scheduling
    * [Block ads](https://github.com/hectorm/hblock) system wide using Hblock to modify the hosts file (Recommended)
    * [Encrypt and cache DNS requests](https://wiki.archlinux.org/index.php/Dnscrypt-proxy) - Enables DNSCrypt and DNSMasq

### Todos
 - Fix cancel option in dialog
 - Move user configs to /etc/skel so new users can get same config setup
 - https://kernelnewbies.org/Linux_5.10#Ext4_fast_commit_support.2C_for_faster_metadata_performance look into this for ext4 performance
