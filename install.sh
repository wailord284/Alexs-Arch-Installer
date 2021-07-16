#!/usr/bin/env bash
#Automated Arch Linux installation script by Alex "wailord284" Gaudino.
###HOW TO USE###
#To use this, burn the Arch Linux ISO to a usb drive and boot it. Once botted download this file.
#If you're on wifi, run wifi-menu(rip) first to connect to the internet or put this script on a second drive to be prompted.
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

#Add repo-ck and chaotic-aur to live ISO pacman config in case user wants custom kernel.
echo '#Repo-ck containing kernels with ck patch
[repo-ck]
Server = https://mirror.lesviallon.fr/$repo/os/$arch
Server = http://repo-ck.com/$arch
SigLevel = Never
[chaotic-aur]
Server = https://random-mirror.chaotic.cx/$repo/$arch
SigLevel = Never
' >> /etc/pacman.conf

#Set time before init
#This is useful if you installed coreboot. The clock will have no time set by default and this will update it.
echo "$yellow""Please wait while the system clock and keyring are set""$reset"
timedatectl set-ntp true
#Set hwclock as well in case system has no battery for RTC
pacman -Syy
pacman -S archlinux-keyring ntp wget dialog --noconfirm
ntpd -qg
hwclock --systohc
gpg --refresh-keys
pacman-key --init
pacman-key --populate
#Stop the reflector.service as it always fails half way in
systemctl stop reflector.service
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

#Username - loop until the username passes the regex check
#Username must only be lowercase with numbers. Anything else fails
usernameCharacters="^[0-9a-z]+$"
#Loop until the username passes the regex check
while : ; do
	user=$(dialog --no-cancel --title "Username" \
		--backtitle "$dialogBacktitle" \
		--inputbox "Please enter a username. Default arch. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	user=${user:-arch}
	if [[ $user =~ $usernameCharacters ]]; then
		break #exit loop
	else
		dialog --msgbox "Username does not contain valid characters. Please try again with lowercase or numbers only." "$dialogHeight" "$dialogWidth" && clear
	fi
done
clear

#Password input - run in a loop in case user enters wrong password
#for some reason 2>&1 needs to be first or else password gets leaked in the text field for a second when you press enter
while : ; do
	#pass1
	pass1=$(dialog --no-cancel --title "Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter a password (Hidden). Default pass. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	pass1=${pass1:-pass}
	#pass2
	pass2=$(dialog --no-cancel --title "Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter your password again (Hidden). Default pass. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	pass2=${pass2:-pass}
	if [ "$pass1" = "$pass2" ]; then
		pass="$pass1"
		break #exit loop
	else
		dialog --msgbox "Passwords do not match. Please try again." "$dialogHeight" "$dialogWidth" && clear
	fi
done
clear

#hostname - for some reason 2>&1 needs to be first or else hostname doesnt work
host=$(dialog --no-cancel --title "Hostname" \
	--backtitle "$dialogBacktitle" \
	--inputbox "Please enter a hostname. Default linux. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
host=${host:-linux}
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
	mapfile -t dialogDiskSize < <(fdisk -l | grep "Disk /" | cut -d' ' -f 3,4 | sed -e 's, ,,g' -e 's,\,,,g')
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
	dialog --msgbox "Your hard drive is smaller than 8GB. Please use a larger drive." "$dialogHeight" "$dialogWidth"
	exit 1
fi

#Filesystem
unset COUNT MENU_OPTIONS options
for i in $(echo "ext4 xfs btrfs"); do
	COUNT=$((COUNT+1))
	MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
done
sysfilesystem=(dialog --backtitle "$dialogBacktitle" \
	--title "Select your filesystem" \
	--scrollbar \
	--radiolist "Press space to select your filesystem. EXT4 or XFS is the recommended choice." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
options=(${MENU_OPTIONS})
filesystem=$("${sysfilesystem[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear

#Ask user if they want disk encryption
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

#If user wants disk encryption, prompt them for a password twice
if [ "$encrypt" = y ]; then
while : ; do
	#encpass1
	encpass1=$(dialog --no-cancel --title "Disk Encryption Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter a password to encrypt your disk (Hidden). Default pass. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	encpass1=${encpass1:-pass}
	#encpass2
	encpass2=$(dialog --no-cancel --title "Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter your password again to encrypt your disk (Hidden). Default pass. " "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	encpass2=${encpass2:-pass}
	if [ "$encpass1" = "$encpass2" ]; then
		encpass="$encpass1"
		break #exit loop
	else
		dialog --msgbox "encass1 and encpass2 do not match. Please try again" "$dialogHeight" "$dialogWidth" && clear
	fi
done
fi
clear

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

#Kernel
#Ask user if they want a custom kernel
dialog --title "Custom Kernels" \
	--defaultno \
	--backtitle "$dialogBacktitle" \
	--yesno "Do you want to install a custom kernel? This includes optimized releases of Linux-ck and Linux-tkg" "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
optionKernel=$?
if [ "$optionKernel" = 0 ]; then
	kernel="y"
else
	kernel="n"
fi
clear
#If user wants a custom kernel, prompt with linux-ck (repo-ck) and linux-tkg (chaotic-aur) kernels.
#Installation of the kernel will happen at the end
if [ "$kernel" = y ]; then
	unset COUNT MENU_OPTIONS options
	COUNT=-1
	mapfile -t dialogRepoCKKernel < <(pacman -Sl repo-ck | grep linux-ck | cut -d" " -f2 | sed '/-headers/d' | sed 's/$/-headers/' && pacman -Sl chaotic-aur | grep linux-tkg | cut -d" " -f2 | sed '/-headers/d' | sed 's/$/-headers/' )
	for i in $(pacman -Sl repo-ck | grep linux-ck | cut -d" " -f2 | sed '/-headers/d' && pacman -Sl chaotic-aur | grep linux-tkg | cut -d" " -f2 | sed '/-headers/d') ; do
		COUNT=$((COUNT+1))
		MENU_OPTIONS="${MENU_OPTIONS} $i ${dialogRepoCKKernel[$COUNT]} off"
	done
	targetKernel=(dialog --backtitle "$dialogBacktitle" \
	--scrollbar \
	--title "Select a kernel you would like to install" \
	--radiolist "Press space to select your Kernel. If unsure, select linux-ck." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
	options=(${MENU_OPTIONS})
	installKernel=$("${targetKernel[@]}" "${options[@]}" 2>&1 >/dev/tty)
	installKernelHeaders=$(echo "$installKernel" | sed 's/$/-headers/')
fi

#Ask the user if they want to continue with the current options
#https://stackoverflow.com/questions/8467424/echo-newline-in-bash-prints-literal-n
dialog --backtitle "$dialogBacktitle" \
--title "Do you want to install with the following options?" \
--yesno "$(printf %"s\n" "Hostname: $host" "User: $user" "Encryption: $encrypt" "Locale: $locale" "Country Timezone: $countryTimezone" "City Timezone: $cityTimezone" "Install Disk: $storage" "Secure Wipe: $wipe" "Custom Kernel: $kernel" "Filesystem: $filesystem")" "$HEIGHT" "$WIDTH"
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

#Begin disk partitioning
if [ "$boot" = bios ] || [ "$boot" = efi ]; then
	#wipe drive - "${storagePartitions[1]}" is boot partition
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Patitioning Disk" \
	--prgbox "Erasing dirve" "wipefs --all $storage && yes | mkfs.ext4 $storage" "$HEIGHT" "$WIDTH"
	if [ "$boot" = bios ]; then
		#BIOS needs msdos
		parted -s "$storage" mklabel msdos
	else
		#UEFI needs GPT
		parted -s "$storage" mklabel gpt
	fi
	#create fat32 boot partition
	parted -a optimal -s "$storage" mkpart primary fat32 1MiB 512MiB
	parted -s "$storage" set 1 boot on #mark bootable
	#create ext4 root partition
	parted -a optimal -s "$storage" mkpart primary "$filesystem" 512MiB 100%

	#Format partitions for encryption
	if [ "$encrypt" = y ]; then
		clear #Run cryptsetup just in terminal, password will be piped in from $encpass
		echo "$green""Setting up disk encryption. Please wait.""$reset"
		echo "$encpass" | cryptsetup --iter-time 3000 --type luks2 --cipher aes-xts-plain64 --key-size 512 --hash sha512 --pbkdf argon2i luksFormat "${storagePartitions[2]}"
		echo "$encpass" | cryptsetup open "${storagePartitions[2]}" cryptroot
		#Filesystem creation
		if [ "$filesystem" = ext4 ] ; then 
			dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
			--title "Patitioning Disk" \
			--prgbox "Formatting root partition" "mkfs.ext4 -L ArchRoot /dev/mapper/cryptroot" "$HEIGHT" "$WIDTH"
		elif [ "$filesystem" = xfs ] ; then
			dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
			--title "Patitioning Disk" \
			--prgbox "Formatting root partition" "mkfs.xfs -L ArchRoot /dev/mapper/cryptroot" "$HEIGHT" "$WIDTH"
		else
			#BTRFS
			dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
			--title "Patitioning Disk" \
			--prgbox "Formatting root partition" "mkfs.btrfs -f -L ArchRoot /dev/mapper/cryptroot" "$HEIGHT" "$WIDTH"
		fi

		#Mount the BTRFS root partition using -o compress=zstd
		if [ "$filesystem" = btrfs ] ; then
			mount -o compress-force=zstd,noatime /dev/mapper/cryptroot /mnt
		else
			mount -o noatime /dev/mapper/cryptroot /mnt
		fi
	else
		#Format partitions for no encyption
		if [ "$filesystem" = ext4 ] ; then
			dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
			--title "Patitioning Disk" \
			--prgbox "Formatting root partition" "mkfs.ext4 -L ArchRoot ${storagePartitions[2]}" "$HEIGHT" "$WIDTH"
		elif [ "$filesystem" = xfs ] ; then
			dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
			--title "Patitioning Disk" \
			--prgbox "Formatting root partition" "mkfs.xfs -L ArchRoot ${storagePartitions[2]}" "$HEIGHT" "$WIDTH"
		else
			#BTRFS
			dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
			--title "Patitioning Disk" \
			--prgbox "Formatting root partition" "mkfs.btrfs -f -L ArchRoot ${storagePartitions[2]}" "$HEIGHT" "$WIDTH"
		fi

		#Mount the BTRFS root partition using -o compress=zstd
		if [ "$filesystem" = btrfs ] ; then
			mount -o compress-force=zstd,noatime "${storagePartitions[2]}" /mnt
		else
			mount -o noatime "${storagePartitions[2]}" /mnt
		fi
	fi

	#Mount and partition the boot partition
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Patitioning Disk" \
	--prgbox "Formatting boot partition" "mkfs.vfat -n ArchBoot -F32 ${storagePartitions[1]}" "$HEIGHT" "$WIDTH"
	#mount drives
	mkdir /mnt/boot
	mount -o noatime "${storagePartitions[1]}" /mnt/boot
fi
clear


#Install system, grub, mirrors
#add my repo to pacman.conf to install glxinfo later
echo '#wailord284 custom repo with many aur packages
[aurmageddon]
Server = http://wailord284.club/repo/$repo/$arch
SigLevel = Never' >> /etc/pacman.conf

#Sort mirrors
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Sorting mirrors" \
--prgbox "Please wait while mirrors are sorted" "pacman -Syy && pacman -S reflector --noconfirm && reflector --verbose -f 10 --latest 20 --country US --protocol https --age 12 --sort rate --save /etc/pacman.d/mirrorlist" "$HEIGHT" "$WIDTH"

#Remove the following mirrors. For some reason they behave randomly 
sed '/mirror.lty.me/d' -i /etc/pacman.d/mirrorlist
sed '/mirrors.kernel.org/d' -i /etc/pacman.d/mirrorlist

#Begin base system install and install zlib-ng from aurmageddon
clear
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing packages" \
--prgbox "Installing base and base-devel package groups" "pacstrap /mnt base base-devel zlib-ng iptables-nft --noconfirm" "$HEIGHT" "$WIDTH"
#Enable some options in pacman.conf
sed "s,\#\VerbosePkgLists,VerbosePkgLists,g" -i /mnt/etc/pacman.conf
sed "s,\#\ParallelDownloads = 5,ParallelDownloads = 5,g" -i /mnt/etc/pacman.conf
sed "s,\#\Color,Color,g" -i /mnt/etc/pacman.conf
clear


#Install additional software
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional base software" \
--prgbox "Installing base and base-devel package groups" "arch-chroot /mnt pacman -S linux linux-headers linux-firmware mkinitcpio grub efibootmgr dosfstools mtools crda --noconfirm" "$HEIGHT" "$WIDTH"
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

#wailord284/maintainer custom repo with many aur packages
#https://wailord284.club/repo/aurmageddon/x86_64/
[aurmageddon]
Server = https://wailord284.club/repo/$repo/$arch
Server = https://wailord284.club/repo/$repo/$arch
SigLevel = Never' >> /mnt/etc/pacman.conf

#Add the ubuntu keyserver to gpg
echo "keyserver keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
echo "keyserver hkp://pgp.mit.edu:11371" >> /mnt/etc/pacman.d/gnupg/gpg.conf

#Sign the repo-ck key
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing repo-ck key" \
--prgbox "Reinstalling the keyring" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman-key -r 5EE46C4C --keyserver keyserver.ubuntu.com && arch-chroot /mnt pacman-key --lsign-key 5EE46C4C " "$HEIGHT" "$WIDTH"
clear

#Sign the chaotic-aur key
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing Chaotic-aur key" \
--prgbox "Reinstalling the keyring" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman-key --keyserver keyserver.ubuntu.com --recv-key 3056513887B78AEB && arch-chroot /mnt pacman-key --lsign-key 3056513887B78AEB && arch-chroot /mnt pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-'{keyring,mirrorlist}'.pkg.tar.zst' --noconfirm" "$HEIGHT" "$WIDTH"
clear

#reinstall keyring in case of gpg errors and add archlinuxcn/chaotic keyrings
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing Archlinuxcn keyring" \
--prgbox "Reinstalling the keyring" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman -S archlinux-keyring archlinuxcn-keyring --noconfirm" "$HEIGHT" "$WIDTH"
clear

#install desktop and software
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional packages" \
--prgbox "Installing desktop environment" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman -S wget nano xfce4-panel xfce4-whiskermenu-plugin xfce4-taskmanager xfce4-cpufreq-plugin xfce4-pulseaudio-plugin xfce4-sensors-plugin xfce4-screensaver thunar-archive-plugin dialog lxdm network-manager-applet nm-connection-editor networkmanager-openvpn networkmanager libnm xfce4 yay grub-customizer baka-mplayer gparted gnome-disk-utility thunderbird xfce4-terminal file-roller pigz lzip lzop cpio lrzip zip unzip p7zip htop libreoffice-fresh hunspell-en_US jre-openjdk jdk-openjdk zafiro-icon-theme transmission-gtk bleachbit gnome-calculator geeqie mpv gedit gedit-plugins papirus-icon-theme ttf-ubuntu-font-family ttf-ibm-plex bash-completion pavucontrol redshift youtube-dl ffmpeg atomicparsley ntp openssh gvfs-mtp cpupower ttf-dejavu ttf-symbola ttf-liberation noto-fonts pulseaudio-alsa xfce4-notifyd xfce4-netload-plugin xfce4-screenshooter dmidecode macchanger pbzip2 smartmontools speedtest-cli neofetch net-tools xorg-xev dnsmasq downgrade nano-syntax-highlighting s-tui imagemagick libxpresent freetype2 rsync screen acpi keepassxc xclip noto-fonts-emoji unrar bind-tools arch-install-scripts earlyoom arc-gtk-theme ntfs-3g memtest86+ xorg-xrandr iotop libva-mesa-driver mesa-vdpau libva-vdpau-driver libva-utils gpart pinta haveged irqbalance xf86-video-fbdev xf86-video-intel xf86-video-amdgpu xf86-video-ati xf86-video-nouveau vulkan-icd-loader firefox firefox-extension-privacybadger firefox-ublock-origin hdparm usbutils logrotate ethtool systembus-notify dbus-broker gpart peek firefox-clearurls tldr compsize kitty iwd --noconfirm" "$HEIGHT" "$WIDTH"
clear

#additional aurmageddon packages
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional packages" \
--prgbox "Installing Aurmageddon packages" "arch-chroot /mnt pacman -S surfn-icons-git pokeshell arch-silence-grub-theme-git archlinux-lxdm-theme-full bibata-cursor-translucent usbimager kernel-modules-hook matcha-gtk-theme nordic-theme-git pacman-cleanup-hook ttf-unifont materiav2-gtk-theme layan-gtk-theme-git lscolors-git zramswap prelockd preload firefox-extension-canvasblocker firefox-extension-localcdn firefox-extension-user-agent-switcher skeuos-gtk-theme-git --noconfirm" "$HEIGHT" "$WIDTH"
clear

#add chaotic-aur and rpeo-ck repo to pacman.conf. Currently nothing is installed from this unless user wants custom kernel
echo '#Chaotic-aur repo with many packages
[chaotic-aur]
Server = https://us-ca-mirror.chaotic.cx/$repo/$arch
Include = /etc/pacman.d/chaotic-mirrorlist' >> /mnt/etc/pacman.conf

if [ "$kernel" = y ]; then
echo '#Repo containing custom compiled kernels with linux-ck
[repo-ck]
Server = https://mirror.lesviallon.fr/$repo/os/$arch
Server = http://repo-ck.com/$arch
Server = http://repo-ck.com/$arch' >> /mnt/etc/pacman.conf
fi

#Update repos
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Updating pacman repos" \
--prgbox "Updating pacman repos for chaotic-aur" "arch-chroot /mnt pacman -Syy && pacman -Syy" "$HEIGHT" "$WIDTH"
clear

#If user wants a custom kernel, install it here
if [ "$kernel" = y ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Custom kernel" \
	--prgbox "Install custom kernel and headers" "arch-chroot /mnt pacman -S $(echo $installKernel $installKernelHeaders) --noconfirm" "$HEIGHT" "$WIDTH"
fi

#Enable services
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Enabling Services" \
--prgbox "Enabling core systemd services" "arch-chroot /mnt systemctl enable NetworkManager ntpdate ctrl-alt-del.target earlyoom zramswap lxdm linux-modules-cleanup haveged irqbalance logrotate.timer" "$HEIGHT" "$WIDTH"

#If the user is using BTRFS, enable BTRFS-scrub service
if [ "$filesystem" = btrfs ] ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Enabling Services" \
	--prgbox "Enabling BTRFS Scrub" "arch-chroot /mnt systemctl enable btrfs-scrub@-.timer" "$HEIGHT" "$WIDTH"
fi

#Enable fstrim if an ssd is detected using lsblk -d -o name,rota. Will return 0 for ssd
#This works however, if you install via usb itll detect the usb drive as nonrotational and enable fstrim
if lsblk -d -o name,rota | grep "0" > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Enabling Services" \
	--prgbox "Enable FStrim" "arch-chroot /mnt systemctl enable fstrim.timer" "$HEIGHT" "$WIDTH"
fi
clear

#Enable prelockd and preload daemon if ram is over ~2GB - https://github.com/hakavlad/prelockd https://wiki.archlinux.org/index.php/Preload
ramTotal=$(grep MemTotal /proc/meminfo | grep -Eo '[0-9]*')
if [ "$ramTotal" -gt "2000000" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Enabling Services" \
	--prgbox "Enabling prelock and preload daemon" "arch-chroot /mnt systemctl enable prelockd.service preload.service" "$HEIGHT" "$WIDTH"
fi
clear

#Dbus-broker setup. Disable dbus and then enable dbus-broker. systemctl --global enables dbus-broker for all users
#https://wiki.archlinux.org/index.php/D-Bus#Alternative_Implementations
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Enabling Services" \
--prgbox "Enabling core systemd services" "arch-chroot /mnt systemctl disable dbus.service && arch-chroot /mnt systemctl enable dbus-broker.service && arch-chroot /mnt systemctl --global enable dbus-broker.service" "$HEIGHT" "$WIDTH"
clear


#Determine installed GPU - by default we now install the stuff required for AMD/Intel since those just autoload drivers
#Nvidia will still auto detect so we can install the proprietary driver
#The below stuff is now set to install vulkan drivers and hardware decoding for correct hardware
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Detecting hardware" \
--prgbox "Finding system graphics card" "pacman -S lshw --noconfirm" "$HEIGHT" "$WIDTH"
#https://www.cyberciti.biz/faq/linux-tell-which-graphics-vga-card-installed/
if lshw -class display | grep "Advanced Micro Devices" || dmesg | grep amdgpu > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found AMD Graphics card" "arch-chroot /mnt pacman -S amdvlk vulkan-radeon --noconfirm" "$HEIGHT" "$WIDTH"
fi
if lshw -class display | grep "Intel Corporation" || dmesg | grep "i915 driver" > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found Intel Graphics card" "arch-chroot /mnt pacman -S vulkan-intel libva-intel-driver intel-media-driver --noconfirm" "$HEIGHT" "$WIDTH"
fi
#if lshw -class display | grep "Nvidia Corporation" || dmesg | grep "nouveau" > /dev/null 2>&1 ; then
#	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
#	--title "Detecting hardware" \
#	--prgbox "Found NVidia Graphics card" "arch-chroot /mnt pacman -S nvidia nvidia-utils nvidia-settings libxnvctrl --noconfirm" "$HEIGHT" "$WIDTH"
#fi
clear


#Find all network interfaces, and add them to /etc/issue to display IP address
#for interface in $(netstat -i | cut -d" " -f 1 | sed -e 's/Kernel//g' -e 's/Iface//g' -e '/^$/d' | sort -u) ; do
#	echo "IP Address for $interface: \4{$interface}" >> /mnt/etc/issue
#done


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


#Change pulseaudio to have higher priority and enable realtime priority - https://wiki.archlinux.org/index.php/Gaming#Enabling_realtime_priority_and_negative_nice_level
sed "s,\; high-priority = yes,high-priority = yes,g" -i /mnt/etc/pulse/daemon.conf
sed "s,\; nice-level = -11,nice-level = -11,g" -i /mnt/etc/pulse/daemon.conf
sed "s,\; realtime-scheduling = yes,realtime-scheduling = yes,g" -i /mnt/etc/pulse/daemon.conf
sed "s,\; realtime-priority = 5,realtime-priority = 5,g" -i /mnt/etc/pulse/daemon.conf


#add sudo changes
sed "s,\#\ %wheel ALL=(ALL) ALL, %wheel ALL=(ALL) ALL,g" -i /mnt/etc/sudoers
echo 'Defaults !tty_tickets' >> /mnt/etc/sudoers
echo 'Defaults passwd_tries=5' >> /mnt/etc/sudoers
echo 'Defaults passwd_timeout=0' >> /mnt/etc/sudoers
echo 'Defaults env_reset,pwfeedback' >> /mnt/etc/sudoers
echo 'Defaults editor=/usr/bin/rnano' >> /mnt/etc/sudoers
echo 'Defaults  log_host, log_year, logfile="/var/log/sudo.log"' >> /mnt/etc/sudoers
echo "#$user ALL=(ALL) NOPASSWD:/usr/bin/pacman,/usr/bin/yay,/usr/bin/cpupower,/usr/bin/iotop,/usr/bin/poweroff,/usr/bin/reboot,/usr/bin/machinectl" >> /mnt/etc/sudoers


#set a lower systemd timeout
sed "s,\#\DefaultTimeoutStartSec=90s,DefaultTimeoutStartSec=45s,g" -i /mnt/etc/systemd/system.conf
sed "s,\#\DefaultTimeoutStopSec=90s,DefaultTimeoutStopSec=45s,g" -i /mnt/etc/systemd/system.conf


#setup makepkg configure and determine core count
sed "s,\#\MAKEFLAGS=\"-j2\",MAKEFLAGS=\"-j\$(nproc)\",g" -i /mnt/etc/makepkg.conf
sed "s,-mtune=generic,-mtune=native,g" -i /mnt/etc/makepkg.conf
sed "s,\!lto,lto,g" -i /mnt/etc/makepkg.conf
sed "s,\#\RUSTFLAGS=\"-C opt-level=2\",RUSTFLAGS=\"-C opt-level=2 -C target-cpu=native\",g" -i /mnt/etc/makepkg.conf
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
elif [ "$product" = "Standard PC (i440FX + PIIX, 1996)" ] || [ "$hypervisor" = "KVM" ] || [ "$manufacturer" = "kvm" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting virtual machine" \
	--prgbox "Running in KVM - Installing guest additions" "arch-chroot /mnt pacman -S qemu-guest-agent --noconfirm && arch-chroot /mnt systemctl enable qemu-guest-agent.service" "$HEIGHT" "$WIDTH"
elif [ "$product" = "VMware Virtual Platform" ] || [ "$hypervisor" = "VMware" ] || [ "$manufacturer" = "vmware" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting virtual machine" \
	--prgbox "Running in VMWare - Installing guest additions" "arch-chroot /mnt pacman -S xf86-video-vmware xf86-input-vmmouse open-vm-tools --noconfirm && arch-chroot /mnt systemctl enable vmtoolsd.service vmware-vmblock-fuse.service" "$HEIGHT" "$WIDTH"
fi
clear


dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring system" \
--prgbox "Downloading config files" "pacman -S unzip wget --noconfirm && wget https://github.com/wailord284/Arch-Linux-Installer/archive/master.zip && unzip master.zip && rm -r master.zip" "$HEIGHT" "$WIDTH"

#Create /etc/skel dirs for configs to be applied to our new user
mkdir -p /mnt/etc/skel/.config/gtk-3.0/
mkdir -p /mnt/etc/skel/.config/kitty/
mkdir -p /mnt/etc/skel/.local/share/xfce4/
#Move configs files to /etc/skel
#Move kitty config
mv Arch-Linux-Installer-master/configs/kitty.conf /mnt/etc/skel/.config/kitty/
#Move picom config. We don't use picom, but maybe in the future
mv Arch-Linux-Installer-master/configs/picom.conf /mnt/etc/skel/.config/
#Create gtk-2.0 disable recents
mv Arch-Linux-Installer-master/configs/.gtkrc-2.0 /mnt/etc/skel
#Create gtk-3.0 disable recents
mv Arch-Linux-Installer-master/configs/gtk-3.0/settings.ini /mnt/etc/skel/.config/gtk-3.0/
#Create the xfce configs for a wayyy better desktop setup than the xfconfs
mv Arch-Linux-Installer-master/configs/xfce4/ /mnt/etc/skel/.config/
#Default wallpaper from manjaro forum
mv Arch-Linux-Installer-master/configs/ArchWallpaper.jpeg /mnt/usr/share/backgrounds/xfce/
#Bash stuffs and screenrc
mv Arch-Linux-Installer-master/configs/bash/.inputrc /mnt/etc/skel/
mv Arch-Linux-Installer-master/configs/bash/.bashrc /mnt/etc/skel/
mv Arch-Linux-Installer-master/configs/bash/.screenrc /mnt/etc/skel/


#Add user here to get /etc/skel configs
arch-chroot /mnt groupadd -r autologin
arch-chroot /mnt useradd -m -G network,autologin,input,kvm,floppy,audio,storage,uucp,wheel,optical,scanner,sys,video,disk -s /bin/bash "$user"
#create a temp file to store the password in and delete it when the script finishes using a trap
#https://www.pixelstech.net/article/1577768087-Create-temp-file-in-Bash-using-mktemp-and-trap
TMPFILE=$(mktemp) || exit 1
trap 'rm -f "$TMPFILE"' EXIT
#root password and user password and setup stronger password encryption
arch-chroot /mnt echo -e "$pass\n$pass" | passwd
#setup more secure passwd by increasing hashes
sed '/nullok/d' -i /mnt/etc/pam.d/passwd
echo "password required pam_unix.so sha512 shadow nullok rounds=65536" >> /mnt/etc/pam.d/passwd
#Create account passwords
echo "$user":"$pass" > "$TMPFILE"
arch-chroot /mnt chpasswd < "$TMPFILE"
arch-chroot /mnt echo -e "$pass\n$pass" | passwd
#unset the passwords stored in pass1 pass2 pass and encpass encpass1 encpass2
unset pass1 pass2 pass encpass encpass1 encpass2
#Setup stronger password security
#https://wiki.archlinux.org/index.php/Security#User_setup
#Increase delay between password attempts to 4 seconds
echo "auth optional pam_faildelay.so delay=4000000" >> /mnt/etc/pam.d/system-login

#set fonts - https://www.reddit.com/r/archlinux/comments/5r5ep8/make_your_arch_fonts_beautiful_easily/
arch-chroot /mnt ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/10-hinting-full.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
sed "s,\#export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",g" -i /mnt/etc/profile.d/freetype2.sh
#mv -f Arch-Linux-Installer-master/configs/fonts/local.conf /mnt/etc/fonts/local.conf

#Add xorg file that allows the user to press control, alt, backspace to kill xorg (returns to login manager)
mv Arch-Linux-Installer-master/configs/xorg/90-zap.conf /mnt/etc/X11/xorg.conf.d/

#NetworkManager/Network startup scripts
mkdir -p /mnt/etc/NetworkManager/conf.d/
mkdir -p /mnt/etc/NetworkManager/dnsmasq.d/
#configure mac address spoofing on startup via networkmanager. Only wireless addresses are randomized
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
#Set network manager to avoid systemd-resolved. Fixes issue "unit dbus-org.freedesktop.resolve1.service not found" in journal log
mv Arch-Linux-Installer-master/configs/networkmanager/no-systemd-resolve.conf /mnt/etc/NetworkManager/conf.d/
#Create one time ntpdupdate + hwclock to set date
mkdir -p /mnt/etc/systemd/system/ntpdate.service.d
mv Arch-Linux-Installer-master/configs/networkmanager/hwclock.conf /mnt/etc/systemd/system/ntpdate.service.d/
#Allow user in the network group to add/modify/delete networks without a password
mv -f Arch-Linux-Installer-master/configs/polkit-1/50-org.freedesktop.NetworkManager.rules /mnt/etc/polkit-1/rules.d/

#IOschedulers for storage that supposedly increase perfomance
mv Arch-Linux-Installer-master/configs/udev/60-ioschedulers.rules /mnt/etc/udev/rules.d/

#HDParm rule to spin down drives
mv Arch-Linux-Installer-master/configs/udev/69-hdparm.rules /mnt/etc/udev/rules.d/

#Add polkit rule so users in KVM group can use libvirt (you don't need to be in the libvirt group now)
mv -f Arch-Linux-Installer-master/configs/polkit-1/50-libvirt.rules /mnt/etc/polkit-1/rules.d/

#Add gparted  polkit rule for storage group, allow users to not enter a password
mv -f Arch-Linux-Installer-master/configs/polkit-1/00-gparted.rules /mnt/etc/polkit-1/rules.d/
clear


#Change to and if -d /proc/bus/input/devices/wacom
#check and setup touchscreen - like x201T/x220T
if grep -i wacom /proc/bus/input/devices > /dev/null 2>&1 ; then
	mv Arch-Linux-Installer-master/configs/xorg/72-wacom-options.conf /mnt/etc/X11/xorg.conf.d/
fi

#Check and setup touchpad
#Changing autodetect for laptops to check chasis type in hostnamectl
#if grep -i TouchPad /proc/bus/input/devices || grep -i "Lid Switch" /proc/bus/input/devices || arch-chroot /mnt acpi -i | grep -E "Battery[0-9]" > /dev/null 2>&1 ; then
chassisType=$(hostnamectl | grep -Eo "Chassis:.{0,10}" | cut -d" " -f2)
if [ "$chassisType" = laptop ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Laptop Found" \
	--prgbox "Setting up powersaving features" "arch-chroot /mnt pacman -S x86_energy_perf_policy xf86-input-synaptics ethtool tlp tlp-rdw --noconfirm && arch-chroot /mnt systemctl enable tlp.service" "$HEIGHT" "$WIDTH"
	mv Arch-Linux-Installer-master/configs/xorg/70-synaptics.conf /mnt/etc/X11/xorg.conf.d/
	#USB autosuspend
	echo 'ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"' > /mnt/etc/udev/rules.d/50-usb_power_save.rules
	echo "options usbcore autosuspend=5" > /mnt/etc/modprobe.d/usb-autosuspend.conf
	#HDD power save
	echo 'ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"' > /mnt/etc/udev/rules.d/50-hd_power_save.rules
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
sed "s,gtk_theme=Adwaita,gtk_theme=Arc-Dark,g" -i /mnt/etc/lxdm/lxdm.conf

#Netfilter connection tracker
echo "options nf_conntrack nf_conntrack_helper=0" > /mnt/etc/modprobe.d/no-conntrack-helper.conf
#Set wifi region
sed "s,\#WIRELESS_REGDOM=\"US\",WIRELESS_REGDOM=\"US\",g" -i /mnt/etc/conf.d/wireless-regdom

#Systemd services
#https://wiki.archlinux.org/index.php/Network_configuration#Promiscuous_mode - packet sniffing/monitoring
mv Arch-Linux-Installer-master/configs/systemd/promiscuous@.service /mnt/etc/systemd/system/

#Set journal to output log contents to TTY12
mkdir /mnt/etc/systemd/journald.conf.d
mv Arch-Linux-Installer-master/configs/systemd/fw-tty12.conf /mnt/etc/systemd/journald.conf.d/
#Set journal to only keep 512M of logs
mv Arch-Linux-Installer-master/configs/systemd/00-journal-size.conf /mnt/etc/systemd/journald.conf.d/

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
echo "$green""5$reset - Sort mirrors with Reflector for new install $green(recommended)"
echo "$green""6$reset - Enable and install the UFW firewall"
echo "$green""7$reset - Use the iwd wifi backend over wpa_suplicant for NetworkManager"
echo "$green""8$reset - Disable/blacklist bluetooth and webcam"
echo "$green""9$reset - Enable automatic desktop login in lxdm $green(recommended)"
echo "$green""10$reset - Enable daily rootkit detection scan"
echo "$green""11$reset - Block ads system wide using hblock to modify the hosts file $green(recommended)"
echo "$green""12$reset - Encrypt and cache DNS requests - Enables DNSCrypt and DNSMasq"

echo "$reset""Default options are:$green 5 9 11$red q""$reset"
echo "Enter$green 1-19$reset (seperated by spaces for multiple options including (q)uit) or$red q$reset to$red quit$reset"
read -r -p "Options: " selection
selection=${selection:- 5 9 11 q}
	for entry in $selection ;do

	case "${entry[@]}" in

		1)
		#bedrock - https://raw.githubusercontent.com/bedrocklinux/bedrocklinux-userland/0.7/releases
		bedrockVersion="0.7.20"
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
		echo "$green""Blacklisting bluetooth and webcam""$reset"
		#bluetooth
		arch-chroot /mnt systemctl enable rfkill-block@bluetooth
		mv Arch-Linux-Installer-master/configs/modprobe/blacklist-bluetooth.conf /mnt/etc/modprobe.d/
		#webcam
		mv Arch-Linux-Installer-master/configs/modprobe/blacklist-webcam.conf /mnt/etc/modprobe.d/
		sleep 3s
		;;

		9)
		echo "$green""Enabling automatic desktop login""$reset"
		sed "s,\#\ autologin=dgod,\ autologin=$user,g" -i /mnt/etc/lxdm/lxdm.conf
		sleep 3s
		;;

		10)
		#https://donatoroque.wordpress.com/2017/08/13/setting-up-rkhunter-using-systemd/
		echo "$green""Creating and enabling daily rkhunter systemd service""$reset"
		arch-chroot /mnt pacman -S rkhunter --noconfirm
		mv Arch-Linux-Installer-master/configs/systemd/rkhunter.service /mnt/etc/systemd/system/
		mv Arch-Linux-Installer-master/configs/systemd/rkhunter.timer /mnt/etc/systemd/system/
		arch-chroot /mnt systemctl enable rkhunter.timer
		sleep 3s
		;;

		11)
		#run hblock to prevent ads
		echo "$green""Running hblock and enabling hblock.timer - hosts file will be modified""$reset"
		arch-chroot /mnt pacman -S hblock --noconfirm #installed from Aurmageddon
		arch-chroot /mnt hblock
		arch-chroot /mnt systemctl enable hblock.timer
		#Make sure to replace the hostname from archiso
		sed -i "s/archiso/$host/g" /mnt/etc/hosts
		sleep 3s
		;;

		12)
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
