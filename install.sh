#!/bin/bash
#Automated Arch Linux installation script by Alex "wailord284" Gaudino.
###HOW TO USE###
#To use this, burn the Arch Linux ISO to a usb drive and boot it. Once botted download this file.
#If you're on wifi, run wifi-menu first to connect to the internet or put this script on a second drive to be prompted.
#1) wget wailord284.club/repo/install.sh 2) chmod +x install.sh 3) ./install.sh
###ABOUT###
#This script will autodetect a large range of hardware and should automatically configure many systems out of the box.
#This script will install Arch with mainly vanilla settings plus some programs and features I personally use.
#To install applications I like, I've created a custom software repository known as "Aurmageddon"
##Aurmageddon has 1500+ packages that recieve updates every 6 hours. Some software used in this install comes from this repo.
##To view this repo, go to http://wailord284.club/repo/aurmageddon/x86_64/
##This repo is unsigned but personally maintained by me. Package requests go to wailord284 on gmail.
#Please be aware that some of the changes this script will make are focused on settings I enjoy.
#All the post install options are optional but may improve your experience. Some options are selected by default.
#This is an ongoing project of mine and will recieve constant updates and improvements.

###Things to maybe add###
#add permrs https://github.com/gort818/permrs - make systemd timer https://www.putorius.net/using-systemd-timers.html
#add option for fail2ban
#https://wiki.archlinux.org/index.php/Getty#Automatic_login_to_virtual_console
#Change vnstat thing to use cat /sys/class/net/wlan/operstate to see if up or down
#https://askubuntu.com/questions/1094389/what-is-the-use-of-systemd-journal-flush-service
#Add check for nvidia graphics by dmesg | grep nv_backlight
#Change ext4 reserved blocks to 3% instead of 5% (use -m 3 in mkfs.ext4)
#Add E4rat for non ssds
#Maybe add spindown for unused drives - https://wiki.archlinux.org/index.php/Hdparm#Putting_a_drive_to_sleep_directly_after_boot
#Maybe add option for pkgstats - optionally reports installed packages etc...
#Auto-cpufreq https://github.com/AdnanHodzic/auto-cpufreq
#readd the pam lockout after 3 failed passwords - broken in newest update
#look at readding dnsmasq cache in networkmanager - currently sets /etc/resolv.conf to 127.0.0.1
#Consider moving bash and other use configs to /etc/skel
#Reflector might be busted

#colors
#white=$(tput setaf 7)
#purple=$(tput setaf 5)
#blue=$(tput setaf 4)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
red=$(tput setaf 1)
reset=$(tput sgr 0)
##Dialog prgbox
HEIGHT=42
WIDTH=135
#WIDTH=0 #0 auto sets
CHOICE_HEIGHT=40
#dialog options for user input
dialogBacktitle="Alex's Arch Linux Installer"
dialogHeight=20
dialogWidth=80
#wifi check - wget -q --spider http://google.com
#configure internet
#Set time before init
#This is useful if you installed coreboot. The clock will have no time set by default and this will update it.
echo "$yellow""Please wait while the system clock and keyring are set""$reset"
timedatectl set-ntp true
#Set hwclock as well in case system has no battery for RTC
pacman -Sy
pacman -S archlinux-keyring ntp wget dialog --noconfirm
ntpd -qg
hwclock --systohc
gpg --refresh-keys
pacman-key --init
pacman-key --populate
clear

#Welcome messages
dialog --title "Welcome!" \
--backtitle "$dialogBacktitle" \
--timeout 10 \
--ok-label "Begin" \
--msgbox "$(printf %"s\n" "Welcome to Alex's automatic install script!" "To use the default values in the script, press enter.")" \
"$dialogHeight" "$dialogWidth"
clear

#desktop
desktop=${desktop:-xfce}
#hostname - for some reason 2>&1 needs to be first or else hostname doesnt work
host=$(dialog --title "Hostname" \
	--backtitle "$dialogBacktitle" \
	--inputbox "Please enter a hostname. Default archlinux. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
host=${host:-archlinux}
clear

#Username
user=$(dialog --title "Username" \
	--backtitle "$dialogBacktitle" \
	--inputbox "Please enter a username. Default alex. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
user=${user:-alex}
clear

#Password input - run in a loop in case user enters wrong password
#for some reason 2>&1 needs to be first or else password gets leaked in the text field for a second when you press enter
while : ; do
	#pass1
	pass1=$(dialog --title "Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter a password (Hidden). Default pass. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	pass1=${pass1:-pass}
	#pass2
	pass2=$(dialog --title "Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter your password again (Hidden). Default pass. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	pass2=${pass2:-pass}
	if [ "$pass1" = "$pass2" ]; then
		#dialog --pause "Passwords match!" "$dialogHeight" "$dialogWidth" 10
		pass="$pass1"
		break #exit loop
	else
		dialog --msgbox "Pass1 and pass2 do not match. Please try again" "$dialogHeight" "$dialogWidth" && clear
	fi
done
clear

#encrypt
dialog --title "Disk Encryption" \
	--defaultno \
	--backtitle "$dialogBacktitle" \
	--yesno "Do you want to enable disk encryption? " "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
optionEncrypt=$?
if [ "$optionEncrypt" = 0 ]; then
	encrypt="y"
else
	encrypt="n"
fi
clear

#Locale
COUNT=0
#replace space with '+' to avoid splitting, remove leading #
for i in $(cat /etc/locale.gen | tail -n+24 | sed -e 's/  $//' -e 's, ,+,g' -e 's,#,,g') ; do
	COUNT=$((COUNT+1))
	MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
done
syslocale=(dialog --backtitle "$dialogBacktitle" \
	--title "Select your locale" \
	--scrollbar \
	--radiolist "Press space to select your locale" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")

options=(${MENU_OPTIONS})
locale=$("${syslocale[@]}" "${options[@]}" 2>&1 >/dev/tty)
#locale=$(echo "$locale" | sed -e 's,+, ,g')
locale=$(echo "${locale//+/ }")
clear

#Timezone country
unset COUNT MENU_OPTIONS options
COUNT=0

for i in /usr/share/zoneinfo/* ; do
	i=$(basename "$i") #remove the directory path
	COUNT=$((COUNT+1))
	MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
done
systimezone=(dialog --backtitle "$dialogBacktitle" \
	--title "Select your timezone" \
	--scrollbar \
	--radiolist "Press space to select your timezone" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
options=(${MENU_OPTIONS})
countryTimezone=$("${systimezone[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear

#Timezone city
unset COUNT MENU_OPTIONS options systimezone
if [ -d /usr/share/zoneinfo/"$countryTimezone" ]; then #Check to see if the country has additional timezones
	COUNT=0
	for i in /usr/share/zoneinfo/"$countryTimezone"/* ; do
		i=$(basename "$i")
		COUNT=$((COUNT+1))
		MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
	done
systimezone=(dialog --backtitle "$dialogBacktitle" \
	--title "Select the city within your country" \
	--scrollbar \
	--radiolist "Press space to select your timezone city" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
options=(${MENU_OPTIONS})
cityTimezone=$("${systimezone[@]}" "${options[@]}" 2>&1 >/dev/tty)
fi
clear

#Disk
declare -a storagePartitions
while : ; do
	#Choose disk to install to - $storage. Only run if storage device was not set with -s ($optionStorage)
	unset COUNT MENU_OPTIONS options
	COUNT=-1
	mapfile -t dialogDiskSize < <( fdisk -l | grep "Disk /" | cut -d' ' -f 3,4 | sed -e 's, ,,g' -e 's,\,,,g')
	for i in $(fdisk -l | grep "Disk /" | cut -d ' ' -f 2 | sed -e 's,:,,g') ; do
		COUNT=$((COUNT+1))
		MENU_OPTIONS="${MENU_OPTIONS} $i ${dialogDiskSize[$COUNT]} off"
	done
	targetDisk=(dialog --backtitle "$dialogBacktitle" \
		--scrollbar \
		--title "Select the drive to install Arch on" \
		--radiolist "Press space to select your drive" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
	options=(${MENU_OPTIONS})
	installDisk=$("${targetDisk[@]}" "${options[@]}" 2>&1 >/dev/tty)
	#remove '|'
	storage=$(echo "$installDisk" | sed 's/|.*//')
	#determine storage type for partitions - nvme0n1p1, sda1 or mmcblk0p1 - $storagePartitions
	if [[ "$storage" = /dev/nvme* ]]; then
		echo "$green""NVME Storage Device""$reset"
		storagePartitions=([1]="$storage"p1 [2]="$storage"p2)
		break
	elif [[ "$storage" = /dev/mmcblk* ]]; then
		echo "$green""eMMC Storage Device""$reset"
		storagePartitions=([1]="$storage"p1 [2]="$storage"p2)
		break
	elif [[ "$storage" = /dev/sd* ]]; then
		echo "$green""SATA Storage Device""$reset"
		storagePartitions=([1]="$storage"1 [2]="$storage"2)
		break
	else
		dialog --msgbox "Invalid storage device enetered. Must be in the format of /dev/sda, /dev/nvme0n1, /dev/mmcblk0." "$dialogHeight" "$dialogWidth" && exit 1
	fi
done
clear

#Make sure the drive is at least 8GB (8589934592 bytes)
#8589934592 / 1048576 = 8192MB (8GB)
driveSize=$(fdisk -l "$storage" | grep -m1 Disk | cut -d ":" -f 2 | cut -d "," -f 2 | sed -e 's/[^0-9]/ /g' -e 's/ //g')
if [ "$driveSize" -lt "8589934592" ]; then
	dialog --msgbox "Your hard drive is smaller than 8GB. Please use a larger drive" "$dialogHeight" "$dialogWidth"
	exit 1
fi

#disk wipe
dialog --title "Secure Disk Erase" \
	--defaultno \
	--backtitle "$dialogBacktitle" \
	--yesno "Do you want to overwrite the drive with random data? This can take a long time depending on the size and speed of the drive." "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
optionWipe=$?
if [ "$optionWipe" = 0 ]; then
	wipe="y"
else
	wipe="n"
fi
clear

#Ask the user if they want to continue with the current options
#https://stackoverflow.com/questions/8467424/echo-newline-in-bash-prints-literal-n
dialog --backtitle "$dialogBacktitle" \
--title "Do you want to install with the following options?" \
--yesno "$(printf %"s\n" "Hostname: $host" "User: $user" "Encryption: $encrypt" "Locale: $locale" "Country Timezone: $countryTimezone" "City Timezone: $cityTimezone" "Install Disk: $storage" "Secure Wipe: $wipe")" "$HEIGHT" "$WIDTH"
finalInstall=$?
if [ "$finalInstall" = 0 ]; then
	dialog --backtitle "$dialogBacktitle" \
	--title "Install starting!" \
	--timeout 5 --msgbox "Starting install in 5 seconds" "$dialogHeight" "$dialogWidth"
	clear
else
	dialog --backtitle "$dialogBacktitle" \
	--title "Install canceled" \
	--msgbox "Press enter to quit" "$dialogHeight" "$dialogWidth"
	exit 1
fi


#Before starting, wipe the drive if user said y to wipe
if [ "$wipe" = y ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--prgbox "Erasing drive" "shred --verbose --random-source=/dev/urandom -n1 $storage" "$HEIGHT" "$WIDTH"
	clear
fi


#Boot type override. You can manually change this variable to the platform you want to install to.
#This is useful if youre installing on a 64bit uefi device but want a 32bit uefi boot (Ex. moving the drive to a different computer)
#Set boot override to 64 or 32
bootOverride=""

#Start the install
#detect efi/uefi bios
#https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system
#https://forums.gentoo.org/viewtopic-p-5254317.html
if [ -d /sys/firmware/efi/ ]; then #if efi is present in /sys/firmware/ then system is UEFI
	boot="efi" #Set boot to efi
else
	boot="bios" #Set boot to bios
fi
#Also detect the boot arch. Some platforms have a 32bit uefi (NOT to be confused with 32bit cpu)
if [ "$boot" = "efi" ]; then
	bootArch="$(cat /sys/firmware/efi/fw_platform_size)"
fi

#Change boot arch if manually set above
if [ "$bootOverride" = 64 ]; then
	bootArch="64"
	boot="efi"
elif [ "$bootOverride" = 32 ]; then
	bootArch="32"
	boot="efi"
fi

if [[ "$boot" = efi && "$encrypt" = y ]]; then
	#wipe drive - "${storagePartitions[1]}" is boot partition
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "UEFI boot with encryption" \
	--prgbox "Formatting dirve" "wipefs --all $storage && yes | mkfs.ext4 $storage" "$HEIGHT" "$WIDTH"
	#create fat32 efi partition
	parted -s "$storage" mklabel gpt
	parted -s "$storage" mkpart primary fat32 1MiB 512MiB
	parted -s "$storage" set 1 esp on
	#create ext4 root partition
	parted -s "$storage" mkpart primary ext4 512MiB 100%
	#Format partitions
	clear #Run cryptsetup just in terminal
	cryptsetup -v -y --iter-time 3000 --type luks2 --key-size 512 --hash sha512 luksFormat "${storagePartitions[2]}"
	cryptsetup open "${storagePartitions[2]}" cryptroot
	#Format partitions
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "UEFI boot with encryption" \
	--prgbox "Formatting dirve" "mkfs.ext4 /dev/mapper/cryptroot" "$HEIGHT" "$WIDTH"
	mount /dev/mapper/cryptroot /mnt
	#Mount and partition boot drive
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "UEFI boot with encryption" \
	--prgbox "Formatting dirve" "mkfs.vfat -F32 ${storagePartitions[1]}" "$HEIGHT" "$WIDTH"
	#add label to the filesystem
	tune2fs -L ArchLinux "${storagePartitions[2]}"
	fatlabel ${storagePartitions[1]} ArchBoot
	#mount drives
	mkdir /mnt/boot
	mount "${storagePartitions[1]}" /mnt/boot
fi
if [[ "$boot" = efi && "$encrypt" = n ]]; then
	#wipe drive - "${storagePartitions[1]}" is boot partition
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "UEFI boot no encryption" \
	--prgbox "Formatting dirve" "wipefs --all $storage && yes | mkfs.ext4 $storage" "$HEIGHT" "$WIDTH"
	#create fat32 efi partition
	parted -s "$storage" mklabel gpt
	parted -s "$storage" mkpart primary fat32 1MiB 512MiB #551MiB
	parted -s "$storage" set 1 esp on
	#create ext4 root partition
	parted -s "$storage" mkpart primary ext4 512MiB 100% #551MiB
	#Format partitions
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "UEFI boot no encryption" \
	--prgbox "Formatting dirve" "mkfs.vfat -F32 ${storagePartitions[1]} && mkfs.ext4 ${storagePartitions[2]}" "$HEIGHT" "$WIDTH"
	#add label to the filesystem
	tune2fs -L ArchLinux "${storagePartitions[2]}"
	fatlabel ${storagePartitions[1]} ArchBoot
	#Mount drive
	mount "${storagePartitions[2]}" /mnt
	mkdir /mnt/boot
	mount "${storagePartitions[1]}" /mnt/boot
fi
#legacy
if [[ "$boot" = bios && "$encrypt" = y ]]; then
	#wipe drive - "${storagePartitions[1]}" is boot partition
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Legacy BIOS with encryption" \
	--prgbox "Formatting dirve" "wipefs --all $storage && yes | mkfs.ext4 $storage" "$HEIGHT" "$WIDTH"
	#create ext4 boot partition
	parted -s "$storage" mklabel msdos #BIOS needs msdos
	parted -s "$storage" mkpart primary ext4 1MiB 512MiB #bios requires ext4
	parted -s "$storage" set 1 boot on #mark bootable
	#create ext4 root partition
	parted -s "$storage" mkpart primary ext4 512MiB 100%
	#Format partitions
	clear #run in terminal
	cryptsetup -v -y --iter-time 3000 --type luks2 --key-size 512 --hash sha512 luksFormat "${storagePartitions[2]}"
	cryptsetup open "${storagePartitions[2]}" cryptroot
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Legacy BIOS with encryption" \
	--prgbox "Formatting dirve" "mkfs.ext4 /dev/mapper/cryptroot" "$HEIGHT" "$WIDTH"
	mount /dev/mapper/cryptroot /mnt
	#Mount and partition boot drive
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Legacy BIOS with encryption" \
	--prgbox "Formatting dirve" "mkfs.ext4 ${storagePartitions[1]}" "$HEIGHT" "$WIDTH"
	#add label to the filesystem
	tune2fs -L ArchLinux "${storagePartitions[2]}"
	tune2fs -L ArchBoot "${storagePartitions[1]}"
	#mount drives
	mkdir /mnt/boot
	mount "${storagePartitions[1]}" /mnt/boot
fi
if [[ "$boot" = bios && "$encrypt" = n ]]; then
	#wipe drive - "${storagePartitions[1]}" is main partition
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Legacy BIOS without encryption" \
	--prgbox "Formatting dirve" "wipefs --all $storage && yes | mkfs.ext4 $storage" "$HEIGHT" "$WIDTH"
	#Setup drive
	parted -s "$storage" mklabel msdos
	parted -s "$storage" mkpart primary ext4 1MiB 100%
	parted -s "$storage" set 1 boot on
	#Format main partition
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Legacy BIOS without encryption" \
	--prgbox "Formatting dirve" "mkfs.ext4 ${storagePartitions[1]}" "$HEIGHT" "$WIDTH"
	#add label to the filesystem
	tune2fs -L ArchLinux "${storagePartitions[1]}"
	#mount drive
	mount "${storagePartitions[1]}" /mnt
fi
clear

#Install system, grub, mirrors
#add my repo to pacman.conf to install glxinfo later
echo '#My custom repo with many aur packages
[aurmageddon]
Server = http://wailord284.club/repo/$repo/$arch
SigLevel = Never' >> /etc/pacman.conf

#Sort mirrors
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Sorting mirrors" \
--prgbox "Please wait while mirrors are sorted" "pacman -Syy && pacman -S reflector --noconfirm" "$HEIGHT" "$WIDTH"
reflector --verbose -f 10 --latest 20 --country US --protocol https --age 12 --sort rate --save /etc/pacman.d/mirrorlist

#Remove the following mirrors. For some reason they behave randomly 
sed '/mirror.lty.me/d' -i /etc/pacman.d/mirrorlist
sed '/mirrors.kernel.org/d' -i /etc/pacman.d/mirrorlist

#Begin base system install
clear
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing packages" \
--prgbox "Installing base and base-devel package groups" "pacstrap /mnt base base-devel --noconfirm" "$HEIGHT" "$WIDTH"
#Enable some options in pacman.conf
sed "s,\#\VerbosePkgLists,VerbosePkgLists,g" -i /mnt/etc/pacman.conf
sed "s,\#\TotalDownload,TotalDownload,g" -i /mnt/etc/pacman.conf
sed "s,\#\Color,Color,g" -i /mnt/etc/pacman.conf
clear


#Install additional software
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional base software" \
--prgbox "Installing base and base-devel package groups" "arch-chroot /mnt pacman -S linux linux-headers linux-firmware mkinitcpio grub efibootmgr dosfstools mtools os-prober crda --noconfirm" "$HEIGHT" "$WIDTH"
#Install amd or intel ucode based on cpu
vendor=$(cat /proc/cpuinfo | grep -m 1 "vendor" | grep -o "Intel")
if [ "$vendor" = Intel ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Autodetected Intel CPU" \
	--prgbox "Installing Intel Microcode" "arch-chroot /mnt pacman -S intel-ucode --noconfirm" "$HEIGHT" "$WIDTH"
else
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Autodetected AMD CPU" \
	--prgbox "Installing AMD Microcode" "arch-chroot /mnt pacman -S amd-ucode --noconfirm" "$HEIGHT" "$WIDTH"
fi
clear


#Enable encryption mkinitcpio hooks if needed and set zstd compression
#ZSTD compression: https://kernelnewbies.org/Linux_5.9#Support_for_ZSTD_compressed_kernel.2C_ramdisk_and_initramfs
if [ "$encrypt" = y ]; then
	sed "s,HOOKS=(base udev autodetect modconf block filesystems keyboard fsck),HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck),g" -i /mnt/etc/mkinitcpio.conf
fi
sed "s,\#\COMPRESSION=\"zstd\",COMPRESSION=\"zstd\",g" -i /mnt/etc/mkinitcpio.conf
#sed "s,\#\COMPRESSION_OPTIONS=(),COMPRESSION_OPTIONS=(-9),g" -i /mnt/etc/mkinitcpio.conf


#Create FSTAB and use inputs
genfstab -U /mnt >> /mnt/etc/fstab
#Set timezone
if [ -z "$cityTimezone" ]; then
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$countryTimezone" /etc/localtime
else
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$countryTimezone"/"$cityTimezone" /etc/localtime
fi
#set locale and clock
sed "s,\#$locale,$locale,g" -i /mnt/etc/locale.gen
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring system..." \
--prgbox "Setting locale and system clock" "arch-chroot /mnt locale-gen && arch-chroot /mnt hwclock --systohc" "$HEIGHT" "$WIDTH"
#Set language
lang=$(echo "$locale" | cut -d ' ' -f 1)
echo "LANG=$lang" >> /mnt/etc/locale.conf
#set hostname
echo "$host" >> /mnt/etc/hostname
#add hostname and ip stuffs to /etc/hosts
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	"$host".localdomain	"$host"" > /mnt/etc/hosts
clear


#create and add user/password
arch-chroot /mnt groupadd -r autologin
arch-chroot /mnt useradd -m -G network,autologin,input,kvm,floppy,audio,storage,uucp,wheel,optical,scanner,sys,video,disk -s /bin/bash "$user"
#create a temp file to store the password in and delete it when the script finishes using a trap
#https://www.pixelstech.net/article/1577768087-Create-temp-file-in-Bash-using-mktemp-and-trap
TMPFILE=$(mktemp) || exit 1
trap 'rm -f "$TMPFILE"' EXIT
#root password and user password and setup stronger password encryption
arch-chroot /mnt echo -e "$pass\n$pass" | passwd
sed '/nullok/d' -i /mnt/etc/pam.d/passwd
#setup more secure passwd by increasing hashes
echo "password required pam_unix.so sha512 shadow nullok rounds=65536" >> /mnt/etc/pam.d/passwd
echo "$user":"$pass" > "$TMPFILE"
arch-chroot /mnt chpasswd < "$TMPFILE"
arch-chroot /mnt echo -e "$pass\n$pass" | passwd
#unset the passwords stored in pass1 pass2 pass and encpass encpass1 encpass2
unset pass1 pass2 pass encpass encpass1 encpass2
#Setup stronger password security
#https://wiki.archlinux.org/index.php/Security#User_setup
#Increase delay between password attempts to 4 seconds
echo "auth optional pam_faildelay.so delay=4000000" >> /mnt/etc/pam.d/system-login
#Lockout a user after 10 failed attempts for 10 mins
#unlock a user with: pam_tally2 --reset --user username
echo "#unlock a user account with: pam_tally2 --reset --user username" >> /mnt/etc/pam.d/system-login
echo "#auth required pam_tally2.so deny=10 unlock_time=600 onerr=succeed file=/var/log/tallylog" >> /mnt/etc/pam.d/system-login


#Install repos - multilib, aurmageddon, archlinuxcn, archstrike and repo-ck
echo '[multilib]
Include = /etc/pacman.d/mirrorlist

#Chia archlinux repo with many aur packages
[archlinuxcn]
Server = https://mirror.xtom.com/archlinuxcn/$arch
Server = http://repo.archlinuxcn.org/$arch
Server = https://cdn.repo.archlinuxcn.org/$arch
#Optional mirrorlists - requires archlinuxcn-mirrorlist-git
#Include = /etc/pacman.d/archlinuxcn-mirrorlist
SigLevel = PackageOptional

#My custom repo with many aur packages
[aurmageddon]
Server = http://wailord284.club/repo/$repo/$arch
SigLevel = Never

#Packages related to pen testing
#Auto install archstrike-setuptool-git
#[archstrike]
#Server = https://mirror.archstrike.org/$arch/$repo
#Include = /etc/pacman.d/archstrike-mirrorlist

#Repo containing custom compiled kernels with linux-ck
#[repo-ck]
#Server = http://repo-ck.com/$arch
#Server = http://repo-ck.com/$arch
#Server = http://repo-ck.com/$arch' >> /mnt/etc/pacman.conf


#reinstall keyring in case of gpg errors
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional packages" \
--prgbox "Reinstalling the keyring" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman -S archlinux-keyring archlinuxcn-keyring --noconfirm" "$HEIGHT" "$WIDTH"
#install desktop and software
#maybe add systembus-notify for earlyoom - becomes a startup service which i dont love
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional packages" \
--prgbox "Installing desktop environment" "arch-chroot /mnt pacman -S wget nano xfce4-panel xfce4-whiskermenu-plugin xfce4-taskmanager xfce4-cpufreq-plugin xfce4-pulseaudio-plugin xfce4-sensors-plugin xfce4-screensaver dialog lxdm network-manager-applet nm-connection-editor networkmanager-openvpn networkmanager libnm xfce4 yay grub-customizer baka-mplayer gparted gnome-disk-utility thunderbird nemo nemo-fileroller xfce4-terminal file-roller pigz lzip lrzip zip unzip p7zip htop libreoffice-fresh hunspell-en_US jdk11-openjdk jre11-openjdk zafiro-icon-theme transmission-gtk bleachbit gnome-calculator geeqie mpv gedit gedit-plugins papirus-icon-theme ttf-ubuntu-font-family ttf-ibm-plex bash-completion pavucontrol redshift youtube-dl ffmpeg atomicparsley ntp openssh gvfs-mtp cpupower ttf-dejavu ttf-symbola ttf-liberation noto-fonts pulseaudio-alsa xfce4-notifyd xfce4-screenshooter dmidecode macchanger pbzip2 smartmontools speedtest-cli neofetch net-tools xorg-xev dnsmasq downgrade nano-syntax-highlighting s-tui imagemagick libxpresent freetype2 rsync screen acpi keepassxc xclip lxqt-policykit unrar bind-tools arch-install-scripts earlyoom arc-gtk-theme ntfs-3g hardinfo memtest86+ xorg-xrandr iotop libva-mesa-driver mesa-vdpau libva-vdpau-driver libva-utils gpart pinta haveged irqbalance xf86-video-intel xf86-video-amdgpu xf86-video-ati vulkan-icd-loader firefox firefox-extension-https-everywhere firefox-extension-privacybadger firefox-ublock-origin --noconfirm" "$HEIGHT" "$WIDTH"
clear
#additional aurmageddon packages
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional packages" \
--prgbox "Installing Aurmageddon packages" "arch-chroot /mnt pacman -S surfn-icons-git pokeshell librewolf-bin arch-silence-grub-theme-git archlinux-lxdm-theme-full bibata-cursor-translucent usbimager kernel-modules-hook matcha-gtk-theme-git nordic-theme-git pacman-cleanup-hook ttf-unifont materiav2-gtk-theme layan-gtk-theme-git lscolors-git zramswap --noconfirm" "$HEIGHT" "$WIDTH"
clear


#Enable services
#Disabled
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Enabling Services" \
--prgbox "Enabling core systemd services" "arch-chroot /mnt systemctl enable NetworkManager ntpdate ctrl-alt-del.target earlyoom zramswap lxdm linux-modules-cleanup haveged irqbalance" "$HEIGHT" "$WIDTH"


#Enable fstrim if an ssd is detected using lsblk -d -o name,rota. Will return 0 for ssd
#This works however, if you install via usb itll detect the usb drive as nonrotational and enable fstrim
if lsblk -d -o name,rota | grep "0" > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Enabling Services" \
	--prgbox "Enable FStrim" "arch-chroot /mnt systemctl enable fstrim.timer" "$HEIGHT" "$WIDTH"
fi
clear


#disabled, replaced with zramswap
#setup zram
#sed "s,zswap_enabled=1,zswap_enabled=0,g" -i /mnt/usr/share/systemd-swap/swap-default.conf
#sed "s,zram_enabled=0,zram_enabled=1,g" -i /mnt/usr/share/systemd-swap/swap-default.conf
#sed "s,zram_count=\${NCPU},zram_count=1,g" -i /mnt/usr/share/systemd-swap/swap-default.conf
#sed "s,\#zram_enabled=0,zram_enabled=1,g" -i /mnt/etc/systemd/swap.conf
#sed "s,\#zram_size=\$(( RAM_SIZE / 4)),zram_size=\$(( RAM_SIZE / 4 )),g" -i /mnt/etc/systemd/swap.conf
#sed "s,zram_count=\${NCPU},zram_count=1,g" -i /mnt/etc/systemd/swap.conf

#Determine installed GPU - by default we now install the stuff required for AMD/Intel since those just autoload drivers
#Nvidia will still auto detect so we can install the proprietary driver
#The below stuff is now set to install vulkan drivers and hardware decoding for correct hardware
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Detecting hardware" \
--prgbox "Finding system graphics card" "pacman -S lshw --noconfirm" "$HEIGHT" "$WIDTH"
#vega=$(lspci | grep 'Radeon RX Vega 56/64') - old
#https://www.cyberciti.biz/faq/linux-tell-which-graphics-vga-card-installed/
if lshw -class display | grep "Advanced Micro Devices" || dmesg | grep amdgpu > /dev/null 2>&1 ; then #|| glxinfo -B | grep "Radeon" ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found AMD Graphics card" "arch-chroot /mnt pacman -S amdvlk vulkan-radeon --noconfirm" "$HEIGHT" "$WIDTH"
fi
if lshw -class display | grep "Intel Corporation" || dmesg | grep "i915 driver" > /dev/null 2>&1 ; then #|| glxinfo -B | grep "Intel" ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found Intel Graphics card" "arch-chroot /mnt pacman -S vulkan-intel libva-intel-driver intel-media-driver --noconfirm" "$HEIGHT" "$WIDTH"
fi
if lshw -class display | grep "Nvidia Corporation" || dmesg | grep "nouveau" > /dev/null 2>&1 ; then #|| glxinfo -B | grep "nouveau" ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found NVidia Graphics card" "arch-chroot /mnt pacman -S nvidia nvidia-utils nvidia-settings libxnvctrl --noconfirm" "$HEIGHT" "$WIDTH"
fi
clear


#setup nano config
sed "s,\#\ set linenumbers, set linenumbers,g" -i /mnt/etc/nanorc
sed "s,\#\ set positionlog, set positionlog,g" -i /mnt/etc/nanorc
sed "s,\#\ set constantshow, set constantshow,g" -i /mnt/etc/nanorc
sed "s,\#\ set titlecolor brightwhite\,magenta, set titlecolor brightwhite\,magenta,g" -i /mnt/etc/nanorc
sed "s,\#\ set statuscolor brightwhite\,magenta, set statuscolor brightwhite\,magenta,g" -i /mnt/etc/nanorc
sed "s,\#\ set errorcolor brightwhite\,red, set errorcolor brightwhite\,red,g" -i /mnt/etc/nanorc
sed "s,\#\ set selectedcolor brightwhite\,cyan, set selectedcolor brightwhite\,cyan,g" -i /mnt/etc/nanorc
sed "s,\#\ set stripecolor \,yellow, set stripecolor yellow,g" -i /mnt/etc/nanorc
sed "s,\#\ set numbercolor magenta, set numbercolor magenta,g" -i /mnt/etc/nanorc
sed "s,\#\ set keycolor brightmagenta, set keycolor brightmagenta,g" -i /mnt/etc/nanorc
sed "s,\#\ set functioncolor magenta, set functioncolor magenta,g" -i /mnt/etc/nanorc
sed "s,\#\ include \"/usr/share/nano/\*.nanorc\", include \"/usr/share/nano/\*.nanorc\",g" -i /mnt/etc/nanorc
echo "include /usr/share/nano-syntax-highlighting/*.nanorc" >> /mnt/etc/nanorc


#add sudo changes
sed "s,\#\ %wheel ALL=(ALL) ALL, %wheel ALL=(ALL) ALL,g" -i /mnt/etc/sudoers
echo 'Defaults !tty_tickets' >> /mnt/etc/sudoers
echo 'Defaults passwd_timeout=0' >> /mnt/etc/sudoers
echo 'Defaults editor=/usr/bin/rnano' >> /mnt/etc/sudoers
echo "#$user ALL=(ALL) NOPASSWD:/usr/bin/pacman,/usr/bin/yay,/usr/bin/cpupower,/usr/bin/iotop,/usr/bin/poweroff,/usr/bin/reboot" >> /mnt/etc/sudoers


#set a lower systemd timeout
sed "s,\#\DefaultTimeoutStartSec=90s,DefaultTimeoutStartSec=45s,g" -i /mnt/etc/systemd/system.conf
sed "s,\#\DefaultTimeoutStopSec=90s,DefaultTimeoutStopSec=45s,g" -i /mnt/etc/systemd/system.conf


#setup makepkg configure and determine core count
#cores=$(lscpu | grep 'CPU(s):' | head -1 | grep -Eo "([0-9]+)")
cores=$(grep -c ^processor /proc/cpuinfo)
sed "s,\#\MAKEFLAGS=\"-j2\",MAKEFLAGS=\"-j$cores\",g" -i /mnt/etc/makepkg.conf
sed "s,-mtune=generic,-mtune=native,g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSGZ=(gzip -c -f -n),COMPRESSGZ=(pigz -c -f -n),g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSBZ2=(bzip2 -c -f),COMPRESSBZ2=(pbzip2 -c -f),g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSXZ=(xz -c -z -),COMPRESSXZ=(xz -e -9 -c -z --threads=0 -),g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSZST=(zstd -c -z -q -),COMPRESSZST=(zstd -c --ultra -22 --threads=0 -),g" -i /mnt/etc/makepkg.conf
sed "s,PKGEXT='.pkg.tar.zst',PKGEXT='.pkg.tar',g" -i /mnt/etc/makepkg.conf


#Detect if running in virtual machine and install guest additions
#product sets to company that produces the system
#hypervisor sets to name of hypervisor software (extra check if dmidecode fails)
#manufacturer - Systemd has built in tools to check for VM (extra extra check)
#https://www.ostechnix.com/check-linux-system-physical-virtual-machine/
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Detecting virtual machine" \
--prgbox "Checking if system is a virtual machine" "pacman -S dmidecode --noconfirm" "$HEIGHT" "$WIDTH"

product=$(dmidecode -s system-product-name)
hypervisor=$(dmesg | grep "Hypervisor detected" | cut -d ":" -f 2 | tr -d ' ')
manufacturer=$(systemd-detect-virt)
if [ "$product" = "VirtualBox" ] || [ "$hypervisor" = "VirtualBox" ] || [ "$manufacturer" = "oracle" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting virtual machine" \
	--prgbox "Running in VirtualBox - Installing guest additions" "arch-chroot /mnt pacman -S xf86-video-vmware virtualbox-guest-utils --noconfirm" "$HEIGHT" "$WIDTH"
elif [ "$product" = "VMware Virtual Platform" ] || [ "$hypervisor" = "VMware" ] || [ "$manufacturer" = "vmware" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting virtual machine" \
	--prgbox "Running in VMWare - Installing guest additions" "arch-chroot /mnt pacman -S xf86-video-vmware xf86-input-vmmouse open-vm-tools --noconfirm && arch-chroot /mnt systemctl enable vmtoolsd.service vmware-vmblock-fuse.service" "$HEIGHT" "$WIDTH"
fi
clear


#create themes, disable recents, disable thunar in session - one time script to be started after creating inital xfce config
#Screensaver does not apply correctly - gets reset to 0 which is blank screen
#disable recents - https://alexcabal.com/disabling-gnomes-recently-used-file-list-the-better-way
#BEGIN NEW XFCE CONFIG!! yay
#Default wallpaper from manjaro forum
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring system" \
--prgbox "Downloading config files" "pacman -S unzip wget --noconfirm && wget https://github.com/wailord284/Arch-Linux-Installer/archive/master.zip && unzip master.zip && rm -r master.zip" "$HEIGHT" "$WIDTH"

#Create gtk-2.0 disable recents
mv Arch-Linux-Installer-master/configs/.gtkrc-2.0 /mnt/home/"$user"/
#Create gtk-3.0 disable recents
mkdir -p /mnt/home/"$user"/.config/gtk-3.0/
mv Arch-Linux-Installer-master/configs/gtk-3.0/settings.ini /mnt/home/"$user"/.config/gtk-3.0/
#Create the xfce configs for a wayyy better desktop setup than the xfconfs
mv Arch-Linux-Installer-master/configs/xfce4/ /mnt/home/"$user"/.config/
#Include xfce helpers
mkdir -p /mnt/home/"$user"/.local/share/xfce4
mv Arch-Linux-Installer-master/configs/local/helpers/ /mnt/home/"$user"/.local/share/xfce4/
#Htop config
mv Arch-Linux-Installer-master/configs/htop/ /mnt/home/"$user"/.config/
#Default wallpaper
mv Arch-Linux-Installer-master/configs/ArchWallpaper.jpeg /mnt/usr/share/backgrounds/xfce/
#Librewolf config - add extension and change default settings
mv Arch-Linux-Installer-master/configs/librewolf/ /mnt/home/"$user"/.librewolf
#Take ownership
arch-chroot /mnt chown -R "$user":"$user" /home/"$user"/.config
arch-chroot /mnt chown -R "$user":"$user" /home/"$user"/.local
arch-chroot /mnt chown -R "$user":"$user" /home/"$user"/.librewolf
arch-chroot /mnt chown -R "$user":"$user" /home/"$user"/.gtkrc-2.0

#Bash stuffs
#https://wiki.archlinux.org/index.php/Readline#Faster_completion
mv Arch-Linux-Installer-master/configs/bash/.inputrc /mnt/home/"$user"/
mv Arch-Linux-Installer-master/configs/bash/.bashrc /mnt/home/"$user"/
arch-chroot /mnt chown -R "$user":"$user" /home/"$user"/.inputrc
arch-chroot /mnt chown -R "$user":"$user" /home/"$user"/.bashrc

#set fonts - https://www.reddit.com/r/archlinux/comments/5r5ep8/make_your_arch_fonts_beautiful_easily/
arch-chroot /mnt ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/10-hinting-full.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
sed "s,\#export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",g" -i /mnt/etc/profile.d/freetype2.sh
mv -f Arch-Linux-Installer-master/configs/fonts/local.conf /mnt/etc/fonts/local.conf

#Add xorg file that allows the user to press control, alt, backspace to kill xorg (returns to login manager)
mv Arch-Linux-Installer-master/configs/xorg/90-zap.conf /mnt/etc/X11/xorg.conf.d/

#NetworkManager/Network startup scripts
#interface=$(ip a | grep "state UP" | cut -c4- | sed 's/:.*//')
#configure mac address spoofing on startup via networkmanager
mkdir -p /mnt/etc/NetworkManager/conf.d/
mkdir -p /mnt/etc/NetworkManager/dnsmasq.d/
mv Arch-Linux-Installer-master/configs/networkmanager/rand_mac.conf /mnt/etc/NetworkManager/conf.d/
#IPv6 privacy and managed connection
echo -e "[connection]\nipv6.ip6-privacy=2\n[ifupdown]\nmanaged=true" >> /mnt/etc/NetworkManager/NetworkManager.conf
#Use dnsmasq for dns - this is currently disabled - networkmanager sets resolv.conf to 127.0.0.1 when dns=dnsmasq
mv Arch-Linux-Installer-master/configs/networkmanager/dns.conf /mnt/etc/NetworkManager/conf.d/
echo "cache-size=1000" > /mnt/etc/NetworkManager/dnsmasq.d/cache.conf
echo "listen-address=::1" > /mnt/etc/NetworkManager/dnsmasq.d/ipv6_listen.conf
mv Arch-Linux-Installer-master/configs/networkmanager/dnssec.conf /mnt/etc/NetworkManager/dnsmasq.d/
#Set default DNS to cloudflare and quad9
mv Arch-Linux-Installer-master/configs/networkmanager/dns-servers.conf /mnt/etc/NetworkManager/conf.d/
#Create one time ntpdupdate + hwclock to set date
mkdir -p /mnt/etc/systemd/system/ntpdate.service.d
mv Arch-Linux-Installer-master/configs/networkmanager/hwclock.conf /mnt/etc/systemd/system/ntpdate.service.d/
#Allow user in the network group to add/modify/delete networks without a password
#mv -f Arch-Linux-Installer-master/configs/polkit-1/50-org.freedesktop.NetworkManager.rules /mnt/etc/polkit-1/rules.d/

#IOschedulers for storage that supposedly increase perfomance
mv Arch-Linux-Installer-master/configs/udev/60-ioschedulers.rules /mnt/etc/udev/rules.d/
clear


#Change to and if -d /proc/bus/input/devices/wacom
#check and setup touchscreen - like x201T/x220T
if grep -i wacom /proc/bus/input/devices > /dev/null 2>&1 ; then
	mv Arch-Linux-Installer-master/configs/xorg/72-wacom-options.conf /mnt/etc/X11/xorg.conf.d/
fi
#Check and setup touchpad
if grep -i TouchPad /proc/bus/input/devices || grep -i "Lid Switch" /proc/bus/input/devices || arch-chroot /mnt acpi -i | grep -E "Battery[0-9]" > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Laptop Found" \
	--prgbox "Setting up powersaving features" "arch-chroot /mnt pacman -S x86_energy_perf_policy xf86-input-synaptics ethtool tlp tlp-rdw --noconfirm && arch-chroot /mnt systemctl enable tlp.service" "$HEIGHT" "$WIDTH"
	mv Arch-Linux-Installer-master/configs/xorg/70-synaptics.conf /mnt/etc/X11/xorg.conf.d/
	#USB autosuspend
	echo 'ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"' > /mnt/etc/udev/rules.d/50-usb_power_save.rules
	echo "options usbcore autosuspend=5" > /mnt/etc/modprobe.d/usb-autosuspend.conf
	#HDD power save
	echo 'ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"' > /mnt/etc/udev/rules.d/50-hd_power_save.rules
	#HDD Spindown - values of 0-127 let drives spin down (hard drives ONLY)
	echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTRS{queue/rotational}=="1", RUN+="/usr/bin/hdparm -B 127 /dev/%k"' > /etc/udev/rules.d/69-hdparm.rules
	#Laptop mode to save power with spinning drives
	echo "vm.laptop_mode = 5" > /mnt/etc/sysctl.d/00-laptop-mode.conf
	#Disable watchdog - may help with power
	mv Arch-Linux-Installer-master/configs/sysctl/00-disable-watchdog.conf /mnt/etc/sysctl.d/
fi
clear

#Blacklist uncommon modules/protocols
#DISABLED - this will break bridge-utils
#mv Arch-Linux-Installer-master/configs/modprobe/blacklist-uncommon-network-protocols.conf /mnt/etc/modprobe.d/
#load the tcp_bbr module for better network stuffs
echo 'tcp_bbr' > /mnt/etc/modules-load.d/tcp_bbr.conf

#set LXDM theme and session
sed "s,\#\ session=/usr/bin/startlxde,\ session=/usr/bin/startxfce4,g" -i /mnt/etc/lxdm/lxdm.conf
sed "s,theme=Industrial,theme=Archlinux,g" -i /mnt/etc/lxdm/lxdm.conf
sed "s,gtk_theme=Adwaita,gtk_theme=Nordic,g" -i /mnt/etc/lxdm/lxdm.conf

#Netfilter connection tracker
echo "options nf_conntrack nf_conntrack_helper=0" > /mnt/etc/modprobe.d/no-conntrack-helper.conf
#Set wifi region
sed "s,\#WIRELESS_REGDOM=\"US\",WIRELESS_REGDOM=\"US\",g" -i /mnt/etc/conf.d/wireless-regdom

#Systemd services
#https://wiki.archlinux.org/index.php/Network_configuration#Promiscuous_mode - packet sniffing/monitoring
mv Arch-Linux-Installer-master/configs/systemd/promiscuous@.service /mnt/etc/systemd/system/

#Setup sysctl tweaks - Arch stores some defaults in /usr/lib/sysctl.d/
#fix usb speeds - currently disabled due to system lockups when copying files
#mv Arch-Linux-Installer-master/configs/sysctl/00-usb-speed-fix.conf /mnt/etc/sysctl.d/

#Low-level console messages
mv Arch-Linux-Installer-master/configs/sysctl/00-console-messages.conf /mnt/etc/sysctl.d/

#unprivileged_userns_clone
mv Arch-Linux-Installer-master/configs/sysctl/00-unprivileged-userns.conf /mnt/etc/sysctl.d/

#ipv6 privacy
mv Arch-Linux-Installer-master/configs/sysctl/00-ipv6-privacy.conf /mnt/etc/sysctl.d/

#kernel hardening
mv Arch-Linux-Installer-master/configs/sysctl/00-kernel-hardening.conf /mnt/etc/sysctl.d/

#system tweaks
mv Arch-Linux-Installer-master/configs/sysctl/30-system-tweak.conf /mnt/etc/sysctl.d/

#network tweaks
mv Arch-Linux-Installer-master/configs/sysctl/30-network.conf /mnt/etc/sysctl.d/


#grub install - support uefi 64 and 32
if [ "$boot" = efi ]; then
	if [ "$bootArch" = 64 ]; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "EFI Platform" \
		--prgbox "Installing grub for UEFI" "arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --removable --recheck" "$HEIGHT" "$WIDTH"
	else
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "EFI Platform" \
		--prgbox "Installing grub for 32 bit UEFI" "arch-chroot /mnt grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=Arch --removable --recheck" "$HEIGHT" "$WIDTH"
	fi
fi

if [[ "$boot" = bios ]]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "BIOS Platform" \
	--prgbox "Installing grub for legacy BIOS" "arch-chroot /mnt grub-install --target=i386-pc $storage --recheck" "$HEIGHT" "$WIDTH"
fi
clear


#add custom menus to grub
#https://wiki.archlinux.org/index.php/GRUB#EFI_binaries
####ADD - BIOS FLASH/AMDVbflash
#Custom grub binaries - gdisk, uefi shell, flappybird and tetris
#add gdisk menu - https://wiki.archlinux.org/index.php/GPT_fdisk#gdisk_EFI_application
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring grub" \
--prgbox "Downloading grub utilities" "pacman -S p7zip --noconfirm" "$HEIGHT" "$WIDTH"
###TOOLS###
#declare -a grubLinks
#grubLinks=(https://github.com/a1ive/grub2-filemanager/releases/latest/download/grubfm-en_US.7z)

#dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
#--title "Configuring grub" \
#--prgbox "Downloading grub utilities" "wget ${grubLinks[*]}" "$HEIGHT" "$WIDTH"

#Memtest86 - UEFI. Legacy BIOS handled by memtest86+ package
#mount the img file on the target install to not run out of disk space
#once mounted, we extract the UEFI bootable files
#dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
#--title "Configuring grub" \
#--prgbox "Downloading grub utilities" "wget https://www.memtest86.com/downloads/memtest86-usb.zip -P /mnt/memtest && unzip /mnt/memtest/memtest86-usb.zip -d /mnt/memtest/" "$HEIGHT" "$WIDTH"
#mkdir -p /mnt/memtest/memimg
#offset = 512*2048
#mount -o loop,offset=1048576 /mnt/memtest/memtest86-usb.img /mnt/memtest/memimg
#mv /mnt/memtest/memimg/EFI/BOOT/BOOTX64.efi /mnt/boot/EFI/tools/memtestx64.efi
#umount /mnt/memtest/memimg
#rm -r /mnt/memtest

##Changed memtest to download from github
#Move grub boot items
mkdir -p /mnt/boot/EFI/tools
mkdir -p /mnt/boot/EFI/games
mv Arch-Linux-Installer-master/configs/grub/tools/* /mnt/boot/EFI/tools/
mv Arch-Linux-Installer-master/configs/grub/games/*.efi /mnt/boot/EFI/games/
mv Arch-Linux-Installer-master/configs/grub/custom.cfg /mnt/boot/grub/


#Weird PCIE errors for X99 - https://unix.stackexchange.com/questions/327730/what-causes-this-pcieport-00000003-0-pcie-bus-error-aer-bad-tlp
#grub config and unmount - https://make-linux-fast-again.com/ - nowatchdog pci=nommconf intel_pstate=disable acpi-cpufreq
#Generate grubcfg with root UUID if encrypt=y
#Use CPU Random generation: https://security.stackexchange.com/questions/42164/rdrand-from-dev-random
mitigations=$(curl -s https://make-linux-fast-again.com/)
if [ "$encrypt" = y ]; then
	uuid=$(lsblk -dno UUID "${storagePartitions[2]}")
	sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$uuid:cryptroot root=/dev/mapper/cryptroot audit=0 loglevel=3 random.trust_cpu=on $mitigations\",g" -i /mnt/etc/default/grub
fi
#generate grubcfg if no encryption
if [ "$encrypt" = n ]; then
	sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"audit=0 loglevel=3 random.trust_cpu=on $mitigations\",g" -i /mnt/etc/default/grub
fi
#Change timeout
#sed "s,\GRUB_TIMEOUT=5,\GRUB_TIMEOUT=3,g" -i /mnt/etc/default/grub
#Change theme
echo 'GRUB_THEME="/boot/grub/themes/arch-silence/theme.txt"' >> /mnt/etc/default/grub
#generate grubcfg
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring grub" \
--prgbox "Generating grubcfg" "arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg" "$HEIGHT" "$WIDTH"
clear


#optional post install settings
declare -a selection
echo "$green""Installation complete! Here are some optional things you may want to install:""$reset"
echo "$green""1$reset - Install Bedrock Linux"
echo "$green""2$reset - Enable X2Go remote management server"
echo "$green""3$reset - Enable sshd"
echo "$green""4$reset - Route all traffic over Tor"
echo "$green""5$reset - Sort mirrors with Reflector for new install$green(recommended)"
echo "$green""6$reset - Enable and install the UFW firewall"
echo "$green""7$reset - Use the iwd wifi backend over wpa_suplicant for NetworkManager"
echo "$green""8$reset - Restore old network interface names (eth0, wlan0...)"
echo "$green""9$reset - Disable/blacklist bluetooth and webcam"
echo "$green""10$reset - Enable Firejail for all supported applications"
echo "$green""11$reset - Enable vnstat webui traffic monitor"
echo "$green""12$reset - Enable local Searx search engine"
echo "$green""13$reset - Install PlatformIO Udev rules for Arduino Communication"
echo "$green""14$reset - Enable AMD Freesync - Might break Xorg"
echo "$green""15$reset - Enable automatic desktop login in lxdm $green(recommended)"
echo "$green""16$reset - Enable daily rootkit detection scan"
echo "$green""17$reset - Enable Ananicy - Daemon for setting CPU priority and scheduling. May increase performance"
echo "$green""18$reset - Block ads system wide using hblock to modify the hosts file $green(recommended)"
echo "$green""19$reset - Encrypt and cache DNS requests - Enables DNSCrypt and DNSMasq"

echo "$reset""Default options are:$green 5 15 18$red q""$reset"
echo "Enter$green 1-19$reset (seperated by spaces for multiple options including (q)uit) or$red q$reset to$red quit$reset"
read -r -p "Options: " selection
selection=${selection:- 5 15 18 q}
	for entry in $selection ;do

	case "${entry[@]}" in

		1)
		#bedrock - https://raw.githubusercontent.com/bedrocklinux/bedrocklinux-userland/0.7/releases
		bedrockVersion="0.7.19"
		echo "$green""Installing Bedrock Linux""$reset"
		modprobe fuse
		arch-chroot /mnt wget https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/"$bedrockVersion"/bedrock-linux-"$bedrockVersion"-x86_64.sh
		arch-chroot /mnt sh bedrock-linux-"$bedrockVersion"-x86_64.sh --hijack
		arch-chroot /mnt sed "s,timeout = 30,timeout = 3,g" -i /bedrock/etc/bedrock.conf
		sleep 3s
		;;

		2)
		echo "$green""Setting up X2Go server. Will also enable sshd.""$reset"
		arch-chroot /mnt pacman -S x2goserver x2goclient --noconfirm
		arch-chroot /mnt x2godbadmin --createdb
		arch-chroot /mnt systemctl enable x2goserver
		arch-chroot /mnt systemctl enable sshd
		sleep 3s
		;;

		3)
		echo "$green""Enabling sshd""$reset" # AllowUsers, PermitRootLogin no
		arch-chroot /mnt systemctl enable sshd
		sleep 3s
		;;

		4)
		echo "$green""Routing all traffic over Tor""$reset"
		arch-chroot /mnt pacman -S tor torsocks --noconfirm
		#Copy iptables rules
		mv Arch-Linux-Installer-master/configs/tor/iptables.rules /mnt/etc/iptables/
		ln -s /mnt/etc/iptables/iptables.rules /mnt/etc/iptables/ip6tables.rules
		echo -e "nameserver ::1\nnameserver 127.0.0.1" > /mnt/etc/resolv.conf
		chattr +i /mnt/etc/resolv.conf #lock resolv to prevent overwrites
		echo -e "DNSPort 9053\nTransPort 9040\nSocksPort 9050" >> /mnt/etc/tor/torrc
		mkdir -p /mnt/etc/systemd/system/tor.service.d/
		mv Arch-Linux-Installer-master/configs/tor/netcap.conf /mnt/etc/systemd/system/tor.service.d/
		arch-chroot /mnt systemctl enable tor
		arch-chroot /mnt systemctl enable dnsmasq
		#Delete stock dnsmasq config then copy custom one
		rm /mnt/etc/dnsmasq.conf
		mv Arch-Linux-Installer-master/configs/tor/dnsmasq.conf /mnt/etc/dnsmasq.conf
		arch-chroot /mnt systemctl enable iptables.service
		arch-chroot /mnt systemctl enable ip6tables.service
		arch-chroot /mnt usermod -a -G tor "$user"
		sleep 3s
		;;

		5)
		echo "$green""Sorting mirrors""$reset"
		arch-chroot /mnt pacman -S reflector --noconfirm
		arch-chroot /mnt reflector -f 10 --verbose --latest 20 --country US --protocol https --age 12 --sort rate --save /etc/pacman.d/mirrorlist
		sed '/mirror.lty.me/d' -i /mnt/etc/pacman.d/mirrorlist
		sed '/mirrors.kernel.org/d' -i /mnt/etc/pacman.d/mirrorlist
		sleep 3s
		;;

		6)
		echo "$green""Installing and configuring the UFW firewall""$reset"
		arch-chroot /mnt pacman -S ufw gufw --noconfirm
		arch-chroot /mnt ufw default deny
		arch-chroot /mnt ufw allow Transmission
		arch-chroot /mnt ufw limit SSH
		arch-chroot /mnt ufw enable
		arch-chroot /mnt systemctl enable ufw.service
		sleep 3s
		;;

		7)
		echo "$green""Configuring iwd as the default wifi backend in NetworkManager""$reset"
		mv Arch-Linux-Installer-master/configs/networkmanager/wifi_backend.conf /mnt/etc/NetworkManager/conf.d/
		arch-chroot /mnt pacman -S iwd --noconfirm
		sleep 3s
		;;

		8)
		echo "$green""Restoring traditional network interface names""$reset"
		arch-chroot /mnt ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
		sleep 3s
		;;

		9)
		echo "$green""Blacklisting bluetooth and webcam""$reset"
		#bluetooth
		arch-chroot /mnt systemctl enable rfkill-block@bluetooth
		mv Arch-Linux-Installer-master/configs/modprobe/blacklist-bluetooth.conf /mnt/etc/modprobe.d/
		#webcam
		mv Arch-Linux-Installer-master/configs/modprobe/blacklist-webcam.conf /mnt/etc/modprobe.d/
		sleep 3s
		;;

		10)
		#https://wiki.archlinux.org/index.php/Firejail
		echo "$green""Setting up Firejail and pacman hook - will not sandbox Brave browser""$reset"
		arch-chroot /mnt pacman -S firejail firetools --noconfirm
		arch-chroot /mnt firecfg
		mkdir -p /mnt/etc/pacman.d/hooks
		mv Arch-Linux-Installer-master/configs/firejail/firejail.hook /mnt/etc/pacman.d/hooks/

		echo -e "noblacklist ${HOME}/Desktop\nwhitelist ${HOME}/Desktop" >> /mnt/etc/firejail/brave.profile
		arch-chroot /mnt unlink /usr/local/bin/brave
		sleep 3s
		;;

		11)
		echo "$green""Enabling and install vnstat/vnstatui - will be viewable at 127.0.0.1:7000""$reset"
		arch-chroot /mnt pacman -S gd vnstat vnstatui --noconfirm #installed from Aurmageddon
		echo -e "[Unit]
Description = WebUI traffic monitor vnstatui
After = network.target
After = vnstat.service

[Service]
ExecStart = vnstatui -i $(ip a | grep "state UP" | cut -c4- | sed 's/:.*//')

[Install]
WantedBy = multi-user.target" > /mnt/etc/systemd/system/vnstatuiinterface.service

		arch-chroot /mnt systemctl enable vnstat
		arch-chroot /mnt systemctl enable vnstatuiinterface.service
		sleep 3s
		;;

		12)
		echo "$green""Enabling searx search engine - will be viewable at 127.0.0.1:8888""$reset"
		arch-chroot /mnt pacman -S searx --noconfirm #installed from Aurmageddon
		mv Arch-Linux-Installer-master/configs/searx/searx.service /mnt/etc/systemd/system/
		arch-chroot /mnt systemctl enable searx.service
		sleep 3s
		;;

		13)
		#Udev PlatformIO needed for arduino uploading - https://docs.platformio.org/en/latest/faq.html#platformio-udev-rules
		echo "$green""Installing PlatformIO udev rules for Arduino communication""$reset"
		arch-chroot /mnt wget https://raw.githubusercontent.com/platformio/platformio-core/master/scripts/99-platformio-udev.rules -P /etc/udev/rules.d/
		sleep 3s
		;;

		14)
		#https://www.phoronix.com/scan.php?page=news_item&px=AMD-FreeSync-Linux-5.0-Enable
		echo "$green""Configuring AMD Freesync. If Xorg fails to start delete /etc/X11/xorg.conf.d/freesync.conf""$reset"
		mv Arch-Linux-Installer-master/configs/xorg/50-freesync.conf /mnt/etc/X11/xorg.conf.d/

		sleep 10s
		;;

		15)
		echo "$green""Enabling automatic desktop login""$reset"
		sed "s,\#\ autologin=dgod,\ autologin=$user,g" -i /mnt/etc/lxdm/lxdm.conf
		sleep 3s
		;;

		16)
		#https://donatoroque.wordpress.com/2017/08/13/setting-up-rkhunter-using-systemd/
		echo "$green""Creating and enabling daily rkhunter systemd service""$reset"
		arch-chroot /mnt pacman -S rkhunter --noconfirm
		mv Arch-Linux-Installer-master/configs/systemd/rkhunter.service /mnt/etc/systemd/system/
		mv Arch-Linux-Installer-master/configs/systemd/rkhunter.timer /mnt/etc/systemd/system/
		arch-chroot /mnt systemctl enable rkhunter.timer
		sleep 3s
		;;

		17)
		#https://github.com/Nefelim4ag/Ananicy
		echo "$green""Enabling the Ananicy daemon""$reset"
		arch-chroot /mnt pacman -S ananicy-git --noconfirm #installed from Aurmageddon
		arch-chroot /mnt systemctl enable ananicy.service
		sleep 3s
		;;

		18)
		#run hblock to prevent ads
		echo "$green""Running hblock and enabling hblock.timer - hosts file will be modified""$reset"
		arch-chroot /mnt pacman -S hblock --noconfirm #installed from Aurmageddon
		arch-chroot /mnt hblock -l -r
		arch-chroot /mnt systemctl enable hblock.timer
		sleep 3s
		;;

		19)
		#https://wiki.archlinux.org/index.php/Dnsmasq
		#https://wiki.archlinux.org/index.php/NetworkManager#/etc/resolv.conf
		#https://wiki.archlinux.org/index.php/Dnscrypt-proxy
		echo "$green""Setting up DNSCrypt and DNSMasq""$reset"
		arch-chroot /mnt pacman -S dnscrypt-proxy --noconfirm
		#Remove stock network manager configs (Conflict with dnscrypt)
		rm -r /mnt/etc/NetworkManager/dnsmasq.d/*
		rm -r /mnt/etc/NetworkManager/conf.d/dns-servers.conf
		rm -r /mnt/etc/NetworkManager/conf.d/dns.conf
		#Move new network manager dns configs
		mv Arch-Linux-Installer-master/configs/dns/dns.conf /mnt/etc/NetworkManager/conf.d/
		mv Arch-Linux-Installer-master/configs/dns/dns-servers.conf /mnt/etc/NetworkManager/conf.d/
		#Remove stock configs
		rm -r /mnt/etc/resolv.conf
		rm -r /mnt/etc/dnscrypt-proxy/dnscrypt-proxy.toml
		rm -r /mnt/etc/dnsmasq.conf
		#Move custom dnscrypt, dnsmasq and resolv configs files
		mv Arch-Linux-Installer-master/configs/dns/dnscrypt-proxy.toml /mnt/etc/dnscrypt-proxy/
		mv Arch-Linux-Installer-master/configs/dns/dnsmasq.conf /mnt/etc/dnsmasq.conf
		mv Arch-Linux-Installer-master/configs/dns/resolv.conf /mnt/etc/resolv.conf
		#Enable services
		arch-chroot /mnt systemctl enable dnscrypt-proxy.service
		arch-chroot /mnt systemctl enable dnsmasq.service
		sleep 3s
		;;

		q)
		#unmount based on encryption
		if [ "$encrypt" = y ]; then
			umount -R /mnt
			umount -R /mnt/boot
			cryptsetup close cryptroot
		fi
		if [ "$encrypt" = n ]; then
			umount -R /mnt
			umount -R /mnt/boot
		fi
		clear
		echo "$green""Installation Complete. Thanks for installing!""$reset"
		sleep 1s
		exit 0
		;;
	esac
done
