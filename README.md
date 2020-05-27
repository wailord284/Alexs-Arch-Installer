# Alex's Arch Linux Installer
A simple script to automatically install Arch Linux with the XFCE desktop, custom repository and many post install options.

# About
This is a small script I have been working on for over a year to simplify the Arch Linux install process across the many different types of hardware I have. The goal of this script is to install Arch with a useable experience right out of the box while still maintaining a mostly vanilla setup. Since I use my devices for many different things, I have tried to support many different configurations and optional configs/utilities a user may want. Once the script completes the user can implement 15+ optional features that may be beneficial to them.

# How to use
To use this script, you first need to create a bootable USB with the Arch Linux ISO. Once the ISO is booted and connected to the internet (which is required), you can download the script either from github or my website using wget. Both options will be kept up to date. 
To use the script, do the following:
```
wget wailord284.club/repo/install.sh
chmod +x install.sh
./install.sh
```
The script can also be run in a secondary mode which is more traditional for Linux applications.
```
./install.sh --help
Defaults are used during the automated install. If a required option for installation is not specified, you will be prompted.
List of all availible options:

-c	Set the country for the system timezone. A list can be found in /usr/share/zoneinfo. Default = America
-ci	Set the city for the system timezone. A list can be found in /usr/share/zoneinfo/country. Default = Phoenix
-e	Encrypt the main partition. Must be y or n for (y)es or (n)o. Default = n
-h	Set the hostname for the system. Default = archlinux
-p	Set the password for the root and default user account. Default = pass
-s	Specify the storage device to install to. Must be in the format of /dev/sda, /dev/nvme0n1 or /dev/mmcblk0
-u	Set the user for the default account. Do not use any caps. Default = alex
-w	Securely erase the drive before install using random data and shred. Must be y or n for (y)es or (n)o. Default = n
--help	Show this menu!
```
The user will now be prompted to supply basic information such as hostname, username, password, timezone, disk to install to, disk encryption and full disk wipe. Each option has a "default" which can be used by pressing enter without entering any text. Use y or n for yes and no during prompts if required.
# Features!
- Works with both UEFI and BIOS!
- Automatic detection for Intel, AMD and NVidia graphics
- Automatic detection for Intel and AMD CPUs (installs correct microcode)
- Automatically detect if running in VirtualBox or VMware and install appropriate guest additions
- Optionally overwrite the drive with random data (Secure erase)
- Optional disk encryption for the main root partition (SHA512, Luks2, 3 second iteration time)
- Increased password security (Increased hashing rounds, user lockout and minimum input password time)
- Earlyoom daemon to trigger the Linux OOM killer sooner
- Kernel Modules hook to restore functionality when the running kernel updates
- Pacman cleanup hook to clean the pacman cache when updating
- FSTrim if a SSD is detected
- Modified IO Schedulers for hard drives, SSDs and NVME drives
- Change mkinitcpio compression to lz4 (Faster but bigger size)
- Custom nanorc file to include syntax highlighting
- Support for Touchscreen devices (such as the Thinkpad X201T/X220T)
- Modified trackpad behavior to be more comfortable (if system detected as laptop)
- Implement USB and hard drive power saving features (if system detected as laptop)
- Enable TLP (if system detected as laptop)
- Modified freetype2 and fonts/local.conf to improve font rendering (default font: Ubuntu)
- Slightly modified XFCE configuration to enable compositing, change font and change theme
- Disabled "Recents" found in most file managers
- LXDM display manager with Archlinux theme
- Large amount of sysctl.d/ configs gathered from the Arch wiki to increase performance and stability
- Add the Archlinuxcn repository for additional software
- Install rng-tools if system entropy is under 1800 during time of install
- Bash changes:
    * Custom .inputrc to add color and improve tab completion
    * Add colored output to ls (installed ls-colors-git)
    * Custom aliases for yay/pacman and other system tasks
    * ASCII Pokemon on terminal startup
- Grub changes:
    * Disabled spectre/meltdown patches (Increase performance. Edit /etc/defult/grub to remove)
    * Custom menus
    * Arch Linux theme
    * Reboot, shutdown, File Manager for both UEFI/BIOS
    * UEFI Only tools: UEFI Shell, GDisk partition editor, Chipset reader
    * UEFI Only games: Tetris, Flappybird, UEFIBoy BG/GBC emulator
    * Please note some UEFI tools will only work if the UEFI is newer (UEFI shell v1 works on all systems)
- Makepkg changes:
    * Change makeflags to account for all cores in the system (-j)
    * Change -mtune=generic to native
    * Use .tar as default package extension (No compression)
    * Add multithreaded capable compression programs for makepkg supported files
    * Enable max compression when compressing .xz and .zst (If package extension changed to .pkg.tar.xz or .zst)
- Systemd changes:
    * SystemD service timeout changed from 90 seconds to 45 seconds
    * Enable systemd-zram instead of traditional swap (sets to 1/4 total RAM)
    * Promiscuous mode systemd service to make packet sniffing easier (disabled by default)
- Sudo changes:
    * Prevent password timeout when running long commands
    * Allow multiple TTYs to run sudo after one TTY has successfully ran sudo
    * visudo editor changed to nano
    * Commented line to run specific commands without requiring sudo password
- Modified NetworkManager setup
    * Random wireless MAC address
    * Increased IPv6 privacy
    * DNS cacheing and handeling by dnsmasq
    * Secure DNS servers (1.1.1.1, 1.0.0.1, 9.9.9.9)
    * Automatic hardware clock updates using NTP (Updates everytime device connects to internet)
- Aurmageddon repository maintained by me. Contains 1500+ packages updated every 6 hours.
    * Packages installed from Aurmageddon include: 
    * ```arch-silence-grub-theme-git archlinux-lxdm-theme-full bibata-cursor-translucent imagewriter kernel-modules-hook matcha-gtk-theme-git nordic-theme-git pacman-cleanup-hook ttf-ms-fonts ttf-unifont update-grub materiav2-gtk-theme layan-gtk-theme-git lscolors-git pokeshell```
    * View the public repository here: http://wailord284.club/repo/aurmageddon/x86_64/
- Post Install Options (All optional)
    * Once the installation is complete the user will be prompted with optional settings/configs
    * Bedrock Linux (Not reversible)
    * X2Go remote management server
    * Enable SSHD
    * Route all traffic over Tor (Not reversible)
    * Sort mirrors with Reflector (Recommended)
    * Use the IWD wifi backend instead of wpa_supplicant for NetworkManager (Recommended)
    * Restore old network interface names (eth0, wlan0...)
    * Disable/Blacklist bluetooth and webcam (Recommended)
    * Enable Firejail for all supported applications
    * Enable VNstat webui traffic monitor
    * Enable local Searx search engine
    * Install PlatformIO Udev rules for Arduino Communication
    * Enable AMD Freesync (May break Xorg)
    * Enable automatic desktop login with LXDM (Recommended)
    * Enable daily rootkit detection scan
    * Enable Ananicy - Daemon for setting CPU priority and scheduling
    * Block ads system wide using Hblock to modify the hosts file (Recommended)
    * Enable IRQBalance - helps balance the cpu load generated by interrupts across all of a systems CPU
    * Enable Haveged - increase system entropy and randomness (removes rng-tools if auto installed)

### Todos

 - Create second XFCE config (Once for laptops that shows the battery icon)
 - Change some if statements to use if -d (For touchpad/wacom)
 - Cleanup comments/echo commands
 - Add better support for NVidia detection
