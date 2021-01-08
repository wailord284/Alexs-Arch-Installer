# Alex's Arch Linux Installer
A simple script to automatically install Arch Linux with the XFCE desktop, custom repository and many post install options.

# About
This is a small script I have been working on for over a year to simplify the Arch Linux install process across the many different types of hardware I have. The goal of this script is to install Arch with a useable experience right out of the box while still maintaining a mostly vanilla setup. Since I use my devices for many different things, I have tried to support many different configurations and optional configs/utilities a user may want. Once the script completes the user can implement 20+ optional features that may be beneficial to them.

# How to use
To use this script, you first need to create a bootable USB with the Arch Linux ISO. Once the ISO is booted and connected to the internet (which is required), you can download the script either from github or my website using curl. Both options will be kept up to date. Make sure you run the script using bash, otherwise zsh will interpret the script and error.
To use the script, do the following:
```
curl https://wailord284.club/repo/install.sh -o install.sh
chmod +x install.sh
./install.sh
```
The user will now be prompted to supply basic information such as hostname, username, password, timezone, disk to install to, disk encryption and full disk wipe. Each option has a "default" which can be used by pressing enter without entering any text. Make sure to press space before pressing enter on options that require selecting something from a list.
# Features!
- Works with both UEFI (64 and 32 bit) and BIOS!
- Automatic detection for Intel, AMD and NVidia graphics
- Automatic detection for Intel and AMD CPUs (installs correct microcode)
- Automatically detect if running in VirtualBox or VMware and install appropriate guest additions
- Optionally overwrite the drive with random data (Secure erase)
- Optional disk encryption for the main root partition (SHA512, Luks2, 3 second iteration time)
- Earlyoom daemon to trigger the Linux OOM killer sooner
- Kernel Modules hook to restore functionality when the running kernel updates
- Pacman cleanup hook to clean the pacman cache when updating
- FSTrim timer if a SSD is detected
- Zram instead of swap (sets to 20% of total ram using zramswap)
- Modified IO Schedulers for hard drives, SSDs and NVME drives
- Change mkinitcpio compression to ZSTD (Added in kernel 5.9)
- Custom nanorc file to include syntax highlighting
- Support for Touchscreen devices (such as the Thinkpad X201T/X220T)
- Modified freetype2 and fonts/local.conf to improve font rendering (default font: Ubuntu)
- Slightly modified XFCE configuration to enable compositing, change font and change theme
- Disabled "Recents" found in most file managers
- LXDM display manager with Archlinux theme
- Large amount of sysctl.d/ configs gathered from the Arch wiki to increase performance and stability
- Xorg keybind (Control + Alt + Backspace) to return to login screen
- Add the Archlinuxcn repository for additional software
- Bash changes:
    * Custom .inputrc to add color and improve tab completion
    * Add colored output to ls (installed ls-colors-git)
    * Custom aliases for yay/pacman and other system tasks
    * ASCII Pokemon on terminal startup
- Laptop Changes (If detected):
    * Modified trackpad behavior to be more comfortable
    * Implement USB and hard drive power saving features
    * Enable TLP and various power saving tweaks
- Grub changes:
    * Disabled spectre/meltdown patches (Increase performance. Edit /etc/defult/grub to remove)
    * Trust CPU Random Number Generation (random.trust_cpu=on) improves boot time
    * Arch Linux theme
    * Reboot, shutdown, File Manager option for both UEFI/BIOS
    * UEFI Only tools: UEFI Shell, GDisk partition editor, Chipset reader
    * UEFI Only games: Tetris, Flappybird
    * Please note some UEFI tools will only work if the UEFI is newer (UEFI shell v1 works on all systems)
- Makepkg changes:
    * Change makeflags to account for all cores in the system (-j)
    * Change -mtune=generic to native
    * Use .tar as default package extension (No compression) when building AUR packages
    * Add multithreaded capable compression programs for supported files
    * Enable max compression when compressing .xz and .zst (If package extension changed to .pkg.tar.xz or .zst)
- Systemd changes:
    * Systemd service timeout changed from 90 seconds to 45 seconds
    * Promiscuous mode systemd service to make packet sniffing easier (disabled by default)
    * Journal log always visible on tty12 (control + alt + F12)
    * Keep only 512MB of journald logs (/var/log/journal)
- Password changes (How the password is stored):
    * Increase hashing rounds and change hash to SHA512
    * 4 second delay between password attempts
    * Lockout a user after 10 failed password attempts within 10 minutes
- Sudo changes:
    * Prevent password timeout when running long commands
    * Allow multiple TTYs to run sudo after one TTY has successfully ran sudo
    * visudo editor changed from vi to nano
    * Commented line to run specific commands without requiring sudo password
- Modified NetworkManager setup:
    * Random wireless MAC address
    * Increased IPv6 privacy
    * DNS cacheing with dnsmasq (currently disabled)
    * Secure DNS servers (1.1.1.1, 1.0.0.1, 9.9.9.9) (replaced by dnscrypt and dnsmasq if selected)
    * Automatic hardware clock updates using NTP (Updates everytime device connects to internet)
- Aurmageddon repository maintained by me. Contains 1500+ packages updated every 6 hours.
    * Packages installed from Aurmageddon include:
    * ```surfn-icons-git pokeshell arch-silence-grub-theme-git archlinux-lxdm-theme-full bibata-cursor-translucent usbimager kernel-modules-hook matcha-gtk-theme-git nordic-theme-git pacman-cleanup-hook ttf-unifont materiav2-gtk-theme layan-gtk-theme-git lscolors-git zramswap```
    * View the public repository here: https://wailord284.club/repo/aurmageddon/x86_64/
- Post Install Options (All optional)
    * Once the installation is complete the user will be prompted with optional settings/configs
    * Convert to Bedrock Linux (Not reversible)
    * X2Go remote management server
    * Enable SSHD
    * Route all traffic over Tor (Not reversible)
    * Sort mirrors with Reflector (Recommended)
    * Use the IWD wifi backend instead of wpa_supplicant for NetworkManager
    * Restore traditional network interface names (eth0, wlan0...)
    * Disable/Blacklist bluetooth and webcam
    * Enable Firejail for all supported applications
    * Enable VNstat webui traffic monitor
    * Enable local Searx search engine
    * Install PlatformIO Udev rules for Arduino Communication
    * Enable AMD Freesync (May break Xorg)
    * Enable automatic desktop login with LXDM (Recommended)
    * Enable daily rootkit detection scan
    * Enable Ananicy - Daemon for setting CPU priority and scheduling
    * Block ads system wide using Hblock to modify the hosts file (Recommended)
    * Encrypt and cache DNS requests - Enables DNSCrypt and DNSMasq

### Todos
 - Move user configs to /etc/skel so new users can get same config setup
 - https://kernelnewbies.org/Linux_5.10#Ext4_fast_commit_support.2C_for_faster_metadata_performance look into this for ext4 performance
