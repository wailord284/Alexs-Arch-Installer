#!/usr/bin/env bash
###ABOUT###
#Automated Arch Linux installation script by Alex "wailord284" Gaudino.
#This script will autodetect a large range of hardware and should automatically configure many systems out of the box.
#This script will install Arch with mainly vanilla settings plus some programs and features I personally use.
#To install applications I like, I've created a custom software repository known as "Aurmageddon"
##Aurmageddon has 1500+ packages that recieve frequent updates. Some software used in this install comes from this repo.
##To view this repo, go to https://wailord284.club/repo/aurmageddon/x86_64/
##This repo is unsigned but personally maintained by me.

#Colors
yellow=$(tput setaf 3)
green=$(tput setaf 2)
red=$(tput setaf 1)
reset=$(tput sgr 0)
#Dialog prgbox
HEIGHT=42
WIDTH=135
#WIDTH=0 #0 auto sets
CHOICE_HEIGHT=40
#Dialog options for user input
dialogBacktitle="Alex's Arch Linux Installer"
dialogHeight=20
dialogWidth=80


###INTERNET CHECK###
curl -s -o /dev/null http://archlinux.com
if [ $? -eq 1 ]; then
	echo -e "$red""No internet connection was found.\nThis installer requires an Internet connection to continue.\nPlease connect to the Internet and try again."
	exit 1
fi


###WELCOME MESSAGE 1###
echo -e "$yellow""Please wait while the system clock and keyring are configured.\nThis can take some time especially on older systems.""$reset"


###CONFIGURE ISO SERVICES###
#Stop the following services as it sometimes fails and prints messages over the dialog prompts. We sort mirrors later
systemctl stop reflector.service qemu-guest-agent.service choose-mirror.service
#Start the pacman key service
systemctl start pacman-init


###ADD REPOS AND MIRRORS###
#Add chaotic-aur to live ISO pacman config in case user wants custom kernel
cat << EOF >> /etc/pacman.conf
[chaotic-aur]
Server = https://random-mirror.chaotic.cx/\$repo/\$arch
SigLevel = Never
#wailord284 custom repo with many aur packages used by Alex's Arch Linux Installer
[aurmageddon]
Server = https://wailord284.club/repo/\$repo/\$arch
SigLevel = Never
EOF
#Add a known good worldwide mirrorlist. Current mirrors on arch ISO are broken(?) or unreliable
cat << EOF > /etc/pacman.d/mirrorlist
Server = https://mirrors.xtom.com/archlinux/\$repo/os/\$arch
Server = https://mirror.arizona.edu/archlinux/\$repo/os/\$arch
Server = https://arch.hu.fo/archlinux/\$repo/os/\$arch
Server = https://mirrors.radwebhosting.com/archlinux/\$repo/os/\$arch
Server = https://mirror.lty.me/archlinux/\$repo/os/\$arch
Server = https://mirror.phx1.us.spryservers.net/archlinux/\$repo/os/\$arch
EOF


###SET TIME###
#This is useful if you installed coreboot or have a dead RTC. The clock may have no time set by default and this will update it
timedatectl set-ntp true
#Sync repos and reinstall/install critical applications. Reinstalling glibc and the keyring helps fix errors if the ISO is outdated
pacman -Syy
pacman -S archlinux-keyring acpi glibc ntp ncurses unzip dmidecode wget dialog reflector lshw --noconfirm
#Sync time with NTP
ntpd -qg
#Set hwclock as well in case system has no battery for RTC
hwclock --systohc
#Refresh all keys to make sure they are up to date
gpg --refresh-keys
pacman-key --init
pacman-key --populate
clear


###WELCOME MESSAGE 2###
dialog --title "Welcome!" \
--backtitle "$dialogBacktitle" \
--timeout 20 \
--ok-label "Begin" \
--msgbox "$(printf %"s\n\n" "Welcome to Alex's Automatic Arch Linux install script!" "Please note, no changes will be made to the system until the final confirmation prompt at the end." "Press control + C to cancel at any time and return to the archiso.")" \
"$dialogHeight" "$dialogWidth"
clear


###KEYMAP###
#We do this right at the start in case the user needs a different layout to operate the next prompts
while : ; do
	for i in $(localectl list-keymaps --no-pager); do
		COUNT=$((COUNT+1))
		MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
	done
	consoleKeymap=(dialog --backtitle "$dialogBacktitle" \
		--title "Keymap" \
		--scrollbar \
		--radiolist "Press space to select your keymap for your keyboard. This is used to ensure all menus can be operated using your keyboard and so all keys actually work as intended." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
	IFS=" " read -r -a options <<< "${MENU_OPTIONS}"
	keymap=$("${consoleKeymap[@]}" "${options[@]}" 2>&1 >/dev/tty)
	#Check if the value is set
	if [[ -z $keymap ]]; then
		dialog --msgbox "Please select an item from the list by pressing space then enter." "$dialogHeight" "$dialogWidth"  && clear
	else
		#Set the keymap locally before continuing
		loadkeys "$keymap"
		break
	fi
done
clear


###USERNAME###
#Loop until the username passes the regex check
#Username must only be lowercase with or without numbers. Anything else fails
usernameCharacters="^[0-9a-z]+$"
#Loop until the username passes the regex check
while : ; do
	user=$(dialog --no-cancel --title "Username" \
		--backtitle "$dialogBacktitle" \
		--inputbox "Please enter a username. Must be lowercase only." "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	if [[ $user =~ $usernameCharacters ]]; then
		break #Exit loop if regex matches
	else
		dialog --msgbox "Username does not contain valid characters. Please try again with lowercase or numbers only." "$dialogHeight" "$dialogWidth" && clear
	fi
done
clear


###USER PASSWORD###
#Password input - run in a loop in case user enters wrong password
#For some reason 2>&1 needs to be first or else password gets displayed in the text field for a second when you press enter
while : ; do
	#pass1
	pass1=$(dialog --no-cancel --title "Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter a password for user $user (Hidden)." "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	#pass2
	pass2=$(dialog --no-cancel --title "Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter the same password again for user $user (Hidden)." "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	if [ "$pass1" = "$pass2" ]; then
		pass="$pass1"
		break #Exit loop if the passwords match
	else
		dialog --msgbox "The provided passwords do not match. Please try again." "$dialogHeight" "$dialogWidth" && clear
	fi
done
clear


###HOSTNAME###
#Hostname - for some reason 2>&1 needs to be first or else hostname doesnt work
host=$(dialog --no-cancel --title "Hostname" \
	--backtitle "$dialogBacktitle" \
	--inputbox "Please enter a hostname." "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
clear


###LOCALE###
unset COUNT MENU_OPTIONS options
COUNT=0
#Replace space with '+' to avoid splitting, then remove leading the #
for i in $(tail -n+24 /etc/locale.gen | sed -e 's/  $//' -e 's, ,+,g' -e 's,#,,g') ; do
	COUNT=$((COUNT+1))
	MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
done
syslocale=(dialog --backtitle "$dialogBacktitle" \
	--title "Locale" \
	--scrollbar \
	--radiolist "Press space to select your locale." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")

IFS=" " read -r -a options <<< "${MENU_OPTIONS}"
locale=$("${syslocale[@]}" "${options[@]}" 2>&1 >/dev/tty)
locale=$(echo "${locale//+/ }")
clear


###TIMEZONE - COUNTRY###
unset COUNT MENU_OPTIONS options
COUNT=0
for i in /usr/share/zoneinfo/* ; do
	#Remove the directory path
	i=$(basename "$i")
	COUNT=$((COUNT+1))
	MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
done
systimezone=(dialog --backtitle "$dialogBacktitle" \
	--title "Timezone" \
	--scrollbar \
	--radiolist "Press space to select your timezone." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
IFS=" " read -r -a options <<< "${MENU_OPTIONS}"
countryTimezone=$("${systimezone[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear


###TIMEZONE - CITY###
#Check to see if the country has additional timezones
unset COUNT MENU_OPTIONS options systimezone
if [ -d /usr/share/zoneinfo/"$countryTimezone" ]; then
	COUNT=0
	for i in /usr/share/zoneinfo/"$countryTimezone"/* ; do
		i=$(basename "$i")
		COUNT=$((COUNT+1))
		MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
	done
systimezone=(dialog --backtitle "$dialogBacktitle" \
	--title "Timezone" \
	--scrollbar \
	--radiolist "Press space to select the region in your timezone." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
IFS=" " read -r -a options <<< "${MENU_OPTIONS}"
cityTimezone=$("${systimezone[@]}" "${options[@]}" 2>&1 >/dev/tty)
fi
clear


###REFLECTOR REGION###
unset COUNT MENU_OPTIONS options
for i in $(reflector --list-countries | sed '1,2d' | cut -c26-28); do
	COUNT=$((COUNT+1))
	MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
done
reflectorRegion=(dialog --backtitle "$dialogBacktitle" \
	--title "Mirror Location" \
	--scrollbar \
	--radiolist "Press space to select your region for mirrorlist sorting. This is used to ensure the fastest download possible." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
IFS=" " read -r -a options <<< "${MENU_OPTIONS}"
region=$("${reflectorRegion[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear


###DISK SELECTION###
#Eventually this will get its own function when i figure it out
declare -a storagePartitions
while : ; do
	#Choose disk to install to - $storage.
	unset COUNT MENU_OPTIONS options
	COUNT=-1
	mapfile -t dialogDiskSize < <(fdisk -l | grep "Disk /" | cut -d' ' -f 3,4 | sed -e 's, ,,g' -e 's,\,,,g')
	for i in $(fdisk -l | grep "Disk /" | cut -d ' ' -f 2 | sed -e 's,:,,g') ; do
		COUNT=$((COUNT+1))
		MENU_OPTIONS="${MENU_OPTIONS} $i ${dialogDiskSize[$COUNT]} off"
	done
	targetDisk=(dialog --backtitle "$dialogBacktitle" \
		--scrollbar \
		--title "Target installation drive" \
		--radiolist "Press space to select your drive. No data will be written at this point." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
	IFS=" " read -r -a options <<< "${MENU_OPTIONS}"
	installDisk=$("${targetDisk[@]}" "${options[@]}" 2>&1 >/dev/tty)
	#Remove '|'
	storage=$(echo "$installDisk" | sed 's/|.*//')
	#Determine storage type for partitions - nvme0n1p1, sda1, vda1 or mmcblk0p1 - $storagePartitions
	if [[ "$storage" = /dev/nvme* ]] || [[ "$storage" = /dev/mmcblk* ]]; then
		storagePartitions=([1]="$storage"p1 [2]="$storage"p2)
		break
	elif [[ "$storage" = /dev/vd* ]] || [[ "$storage" = /dev/sd* ]]; then
		storagePartitions=([1]="$storage"1 [2]="$storage"2)
		break
	else
		dialog --msgbox "Invalid storage device enetered. Must be in the format of /dev/sd[a-z], /dev/vd[a-z], /dev/nvme0n1, /dev/mmcblk0." "$dialogHeight" "$dialogWidth"
	fi
done
clear


###DISK SPACE CHECK###
#Make sure the drive is at least 8GB (8589934592 bytes)
#8589934592 / 1048576 = 8192MB (8GB)
driveSize=$(fdisk -l "$storage" | grep -m1 Disk | cut -d ":" -f 2 | cut -d "," -f 2 | sed -e 's/[^0-9]/ /g' -e 's/ //g')
if [ "$driveSize" -lt "8589934592" ]; then
	dialog --msgbox "Your target drive is smaller than 8GB. Please use a larger drive." "$dialogHeight" "$dialogWidth"
	exit 1
fi


###FILESYSTEM###
unset COUNT MENU_OPTIONS options
for i in $(echo "ext4 xfs btrfs f2fs jfs nilfs"); do
	COUNT=$((COUNT+1))
	MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
done
sysfilesystem=(dialog --backtitle "$dialogBacktitle" \
	--title "Filesystem" \
	--scrollbar \
	--radiolist "Press space to select your filesystem. EXT4 is the recommended choice if you are unsure." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
IFS=" " read -r -a options <<< "${MENU_OPTIONS}"
filesystem=$("${sysfilesystem[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear


###ENCRYPTION###
#Ask user if they want disk encryption
dialog --title "Disk Encryption" \
	--defaultno \
	--backtitle "$dialogBacktitle" \
	--yesno "$(printf %"s\n\n" "Do you want to enable disk encryption for the root partition?" "If you do not know what this means, you can safely press no.")" "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
optionEncrypt=$?
if [ "$optionEncrypt" = 0 ]; then
	encrypt="y"
else
	encrypt="n"
fi
clear


###ENCRYPTION PASSWORD###
#If user wants disk encryption, prompt them for a password twice
if [ "$encrypt" = y ]; then
while : ; do
	#encpass1
	encpass1=$(dialog --no-cancel --title "Disk Encryption Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter a password to encrypt your disk (Hidden)." "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	encpass1=${encpass1:-pass}
	#encpass2
	encpass2=$(dialog --no-cancel --title "Disk Encryption Password" \
		--backtitle "$dialogBacktitle" \
		--passwordbox "Please enter your password again to encrypt your disk (Hidden)." "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
	encpass2=${encpass2:-pass}
	if [ "$encpass1" = "$encpass2" ]; then
		encpass="$encpass1"
		break #Exit loop if encryption passwords match
	else
		dialog --msgbox "The provided passwords do not match. Please try again." "$dialogHeight" "$dialogWidth" && clear
	fi
done
fi
clear


###DISK WIPE###
dialog --title "Secure Disk Erase" \
	--defaultno \
	--backtitle "$dialogBacktitle" \
	--yesno "$(printf %"s\n\n" "Do you want to overwrite the drive with random data? This can take a long time depending on the size and speed of the drive." "This is also NOT recommended on any solid state media as it can shorten the devices life." "If you do not know what this means, you can safely press no.")" "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
optionWipe=$?
if [ "$optionWipe" = 0 ]; then
	wipe="y"
else
	wipe="n"
fi
clear


###CUSTOM KERNEL###
#Ask user if they want a custom kernel
dialog --title "Custom Kernel" \
	--defaultno \
	--backtitle "$dialogBacktitle" \
	--yesno "$(printf %"s\n\n" "Do you want to install a custom kernel? This includes optimized releases of Linux-tkg, a kernel focused on gaming and desktop performance." "The normal Linux kernel will still be installed as a fallback option in case the custom kernel does not work on your hardware." "This option is only recommended for advanced users. If you do not know what this means, you can safely press no.")" "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
optionKernel=$?
if [ "$optionKernel" = 0 ]; then
	kernel="y"
else
	kernel="n"
fi
clear
#Eventually this will get its own function when i figure it out
#If user wants a custom kernel prompt them to choose from all linux-tkg options
#Installation of the kernel will happen later
if [ "$kernel" = y ]; then
	unset COUNT MENU_OPTIONS options
	COUNT=-1
	mapfile -t dialogChaoticKernel < <(pacman -Sl chaotic-aur | grep linux-tkg | cut -d" " -f2 | sed '/-headers/d' | sed 's/$/-headers/')
	for i in $(pacman -Sl chaotic-aur | grep linux-tkg | cut -d" " -f2 | sed '/-headers/d') ; do
		COUNT=$((COUNT+1))
		MENU_OPTIONS="${MENU_OPTIONS} $i ${dialogChaoticKernel[$COUNT]} off"
	done
	targetKernel=(dialog --backtitle "$dialogBacktitle" \
	--scrollbar \
	--title "Custom Kernel" \
	--radiolist "Press space to select your Kernel." "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
	IFS=" " read -r -a options <<< "${MENU_OPTIONS}"
	installKernel=$("${targetKernel[@]}" "${options[@]}" 2>&1 >/dev/tty)
	installKernelHeaders=$(echo "$installKernel" | sed 's/$/-headers/')
fi
clear


###GRUB/SECURITY OPTIONS###
#Ask if user wants to disable security mitigations as well as trust cpu random
#We might add more performance options so lets make it a variable just in case
grubSecurityMitigations="mitigations=off"
dialog --title "Performance Options" \
	--defaultno \
	--backtitle "$dialogBacktitle" \
	--yesno "$(printf %"s\n\n" "Do you want to disable spectre and meltdown mitigations?" "These options will improve performance at the cost of security. This is most impactful on older systems." "If you do not know what this means, you can safely press no." "The following options will be added to Grub if you say yes: $grubSecurityMitigations")" "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
optionDisableMitigations=$?
if [ "$optionDisableMitigations" = 0 ]; then
	disableMitigations="y"
else
	disableMitigations="n"
fi
clear


###FINAL CONFIRMATION###
#Ask the user if they want to continue with the current options
dialog --backtitle "$dialogBacktitle" \
--defaultno \
--title "Do you want to install with the following options?" \
--yesno "$(printf %"s\n" "Do you want to proceed with the installation? If you press yes, all data on the drive will be lost!" "Hostname: $host" "Username: $user" "Encryption: $encrypt" "Locale: $locale" "Keymap: $keymap" "Country Timezone: $countryTimezone" "City Timezone: $cityTimezone" "Mirrorlist location: $region" "Filesystem: $filesystem" "Install Disk: $storage" "Secure Wipe: $wipe" "Custom Kernel: $installKernel" "Disable Mitigations: $disableMitigations")" "$HEIGHT" "$WIDTH"
finalInstall=$?
if [ "$finalInstall" = 0 ]; then
	dialog --backtitle "$dialogBacktitle" \
	--title "Install starting!" \
	--timeout 5 --msgbox "Starting install in 5 seconds!" "$dialogHeight" "$dialogWidth"
	clear
else
	dialog --backtitle "$dialogBacktitle" \
	--title "Install canceled!" \
	--msgbox "Press enter to quit and return to the Arch CLI." "$dialogHeight" "$dialogWidth"
	exit 1
fi


###DISK WIPE###
#Before starting, wipe the drive if user said y to wipe
if [ "$wipe" = y ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--prgbox "Erasing drive" "shred --verbose --random-source=/dev/urandom -n1 $storage" "$HEIGHT" "$WIDTH"
fi
clear


###UEFI AND BIOS CHECK/SETUP###
#Start the install - detect efi/uefi bios
#If efi is present in /sys/firmware/ then system is UEFI
if [ -d /sys/firmware/efi/ ]; then
	boot="efi" #Set boot to efi
else
	boot="bios" #Set boot to bios
fi
#Also detect the boot arch. Some platforms have a 32bit uefi (NOT to be confused with 32bit cpu)
if [ "$boot" = "efi" ]; then
	bootArch="$(cat /sys/firmware/efi/fw_platform_size)"
fi


###DISK PARTITIONING###
#Begin disk partitioning
#https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system
if [ "$boot" = bios ] || [ "$boot" = efi ]; then
	#Wipe drive - "${storagePartitions[1]}" is boot partition
	#We use fdisk to write a new partition table, then wipe it all with wipefs. This should unpartition the drive.
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Patitioning Disk" \
	--prgbox "Erasing dirve" "echo -e 'g\nw' | fdisk $storage && wipefs --all $storage" "$HEIGHT" "$WIDTH"
	if [ "$boot" = bios ]; then
		#BIOS needs msdos
		parted -s "$storage" mklabel msdos
	else
		#UEFI needs GPT
		parted -s "$storage" mklabel gpt
	fi
	#Create fat32 boot partition
	parted -a optimal -s "$storage" mkpart primary fat32 1MiB 512MiB
	#Mark partition 1 as bootable
	parted -s "$storage" set 1 boot on
	#Create root partition/filesystem
	parted -a optimal -s "$storage" mkpart primary "$filesystem" 512MiB 100%
	clear

	#Format partitions for encryption
	if [ "$encrypt" = y ]; then
		#If encryption is set, make rootTargetDisk the cryptroot mapper. Otherwise, set it to ${storagePartitions[2]}
		rootTargetDisk=/dev/mapper/cryptroot
		#Run cryptsetup just in terminal, password will be piped in from $encpass
		echo "$green""Setting up disk encryption. Please wait.""$reset"
		echo "$encpass" | cryptsetup --iter-time 5000 --use-random --type luks2 --cipher aes-xts-plain64 --key-size 512 --pbkdf argon2id luksFormat "${storagePartitions[2]}"
		echo "$encpass" | cryptsetup open "${storagePartitions[2]}" cryptroot
	else
		#If encryption is not set, make this set to ${storagePartitions[2]}
		rootTargetDisk="${storagePartitions[2]}"
	fi

	#Filesystem creation
	if [ "$filesystem" = ext4 ] ; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Patitioning Disk" \
		--prgbox "Formatting root partition" "mkfs.ext4 -L ArchRoot $rootTargetDisk" "$HEIGHT" "$WIDTH"
	elif [ "$filesystem" = xfs ] ; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Patitioning Disk" \
		--prgbox "Formatting root partition" "mkfs.xfs -f -L ArchRoot $rootTargetDisk" "$HEIGHT" "$WIDTH"
	elif [ "$filesystem" = jfs ] ; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Patitioning Disk" \
		--prgbox "Formatting root partition" "yes | mkfs.jfs -L ArchRoot $rootTargetDisk" "$HEIGHT" "$WIDTH"
	elif [ "$filesystem" = nilfs ] ; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Patitioning Disk" \
		--prgbox "Formatting root partition" "yes | mkfs.nilfs2 -L ArchRoot $rootTargetDisk" "$HEIGHT" "$WIDTH"
	elif [ "$filesystem" = f2fs ] ; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Patitioning Disk" \
		--prgbox "Formatting root partition" "mkfs.f2fs -f -l ArchRoot -O extra_attr,inode_checksum,sb_checksum,compression,encrypt $rootTargetDisk" "$HEIGHT" "$WIDTH"
	elif [ "$filesystem" = btrfs ] ; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Patitioning Disk" \
		--prgbox "Formatting root partition" "mkfs.btrfs -f -L ArchRoot $rootTargetDisk" "$HEIGHT" "$WIDTH"
	fi

	if [ "$filesystem" = btrfs ] ; then
		rootTargetDiskUUID=$(lsblk -dno UUID "$rootTargetDisk")
		#Mount the root partition by UUID to make sure genfstab uses UUIDs
		mount -o compress-force=zstd:3,space_cache=v2,noatime,commit=60 -U "$rootTargetDiskUUID" /mnt
		#Create the subvolumes. We do not mount /tmp but make it a subvolume anyways
		btrfs subvolume create /mnt/@
		btrfs subvolume create /mnt/@var_log
		btrfs subvolume create /mnt/@var_cache
		btrfs subvolume create /mnt/@var_tmp
		btrfs subvolume create /mnt/@opt
		btrfs subvolume create /mnt/@tmp
		btrfs subvolume create /mnt/@srv
		#Unmount the root partition
		umount /mnt
		#Remount everything using subvolumes
		mount -o compress-force=zstd:3,space_cache=v2,noatime,commit=60,subvol=@ -U "$rootTargetDiskUUID" /mnt
		#Make the subvolume directories to mount
		mkdir -p /mnt/{srv,var/log,var/cache,var/tmp,opt}
		#Mount the remaining subvoulmes
		mount -o compress-force=zstd:3,space_cache=v2,noatime,commit=60,subvol=@var_log -U "$rootTargetDiskUUID" /mnt/var/log
		mount -o compress-force=zstd:3,space_cache=v2,noatime,commit=60,subvol=@var_cache -U "$rootTargetDiskUUID" /mnt/var/cache
		mount -o compress-force=zstd:3,space_cache=v2,noatime,commit=60,subvol=@var_tmp -U "$rootTargetDiskUUID" /mnt/var/tmp
		mount -o compress-force=zstd:3,space_cache=v2,noatime,commit=60,subvol=@opt -U "$rootTargetDiskUUID" /mnt/opt
		mount -o compress-force=zstd:3,space_cache=v2,noatime,commit=60,subvol=@opt -U "$rootTargetDiskUUID" /mnt/srv
	elif [ "$filesystem" = f2fs ] ; then
		#Mount F2FS root partition using -o compress_algorithm=zstd
		mount -o compress_algorithm=zstd,compress_algorithm=zstd:3 "$rootTargetDisk" /mnt
	else
		#Standard mount for everything else
		mount -o noatime "$rootTargetDisk" /mnt
	fi

	#Mount and partition the boot partition
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Patitioning Disk" \
	--prgbox "Formatting boot partition" "mkfs.vfat -n ArchBoot -F32 ${storagePartitions[1]}" "$HEIGHT" "$WIDTH"
	#Mount drives
	mkdir /mnt/boot
	mount -o noatime "${storagePartitions[1]}" /mnt/boot
fi
clear


###MIRRORLIST SORTING - INSTALLATION MEDIA###
#Sort mirrors
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Sorting mirrors on installation media" \
--prgbox "Please wait while mirrors are sorted" "pacman -Syy && reflector --download-timeout 10 --connection-timeout 10 --verbose -f 10 --latest 20 --country $region --protocol https --age 24 --sort rate --save /etc/pacman.d/mirrorlist" "$HEIGHT" "$WIDTH"
#Remove the following mirrors. For some reason they behave randomly
sed '/mirror.lty.me/d' -i /etc/pacman.d/mirrorlist
sed '/mirrors.kernel.org/d' -i /etc/pacman.d/mirrorlist
sed '/octyl.net/d' -i /etc/pacman.d/mirrorlist
clear


###BASE PACKAGE INSTALL#
#Begin base system install and install zlib-ng from aurmageddon
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing packages" \
--prgbox "Installing base and base-devel package groups" "pacstrap /mnt base base-devel --noconfirm" "$HEIGHT" "$WIDTH"
clear


###PACMAN CONFIG###
#Enable some options in pacman.conf
sed "s,\#\VerbosePkgLists,VerbosePkgLists,g" -i /mnt/etc/pacman.conf
sed "s,\#\ParallelDownloads = 5,ParallelDownloads = 5,g" -i /mnt/etc/pacman.conf
sed "s,\#\Color,Color,g" -i /mnt/etc/pacman.conf


###KERNEL, FIRMWARE, BASE-DEVEL AND MICROCODE INSTALLATION###
#Install additional software
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional base software" \
--prgbox "Installing base and base-devel package groups" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman -S jfsutils nilfs-utils linux linux-headers linux-firmware mkinitcpio grub efibootmgr dosfstools mtools btrfs-progs --noconfirm" "$HEIGHT" "$WIDTH"
#Install amd or intel ucode based on cpu
cpuVendor=$(grep -m 1 "vendor" /proc/cpuinfo | grep -o "Intel")
if [ "$cpuVendor" = Intel ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Autodetected Intel CPU" \
	--prgbox "Installing Intel Microcode" "arch-chroot /mnt pacman -S intel-ucode --noconfirm" "$HEIGHT" "$WIDTH"
else
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Autodetected AMD CPU" \
	--prgbox "Installing AMD Microcode" "arch-chroot /mnt pacman -S amd-ucode --noconfirm" "$HEIGHT" "$WIDTH"
fi
clear


###MKINITCPIO###
#Replace base and udev with systemd. Improves boot time slightly
sed "s,HOOKS=(base udev autodetect modconf block filesystems keyboard fsck),HOOKS=(systemd autodetect keyboard modconf block filesystems fsck),g" -i /mnt/etc/mkinitcpio.conf
#Enable encryption mkinitcpio hook if needed and revert back to base/udev hooks as using the systemd one required additional changes
if [ "$encrypt" = y ]; then
	sed "s,HOOKS=(systemd autodetect keyboard modconf block filesystems fsck),HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck),g" -i /mnt/etc/mkinitcpio.conf
fi
#If the filesystem is btrfs add the btrfs binary to mkinitcpio for recovery situations
if [ "$filesystem" = btrfs ] ; then
	sed "s,BINARIES=(),BINARIES=(btrfs),g" -i /mnt/etc/mkinitcpio.conf
fi
#Arch has now made ZSTD the default. LZ4 is slightly faster but uses more disk space
sed "s,\#\COMPRESSION=\"lz4\",COMPRESSION=\"lz4\",g" -i /mnt/etc/mkinitcpio.conf
#sed "s,\#\COMPRESSION_OPTIONS=(),COMPRESSION_OPTIONS=(-9),g" -i /mnt/etc/mkinitcpio.conf


###FSTAB###
#Create FSTAB
genfstab -U /mnt >> /mnt/etc/fstab
#If the filesystem is F2FS remove the relatime mount option as it also adds lazytime which is better
if [ "$filesystem" = f2fs ]; then
	sed 's/relatime,//' -i /mnt/etc/fstab
fi


###TIMEZONE###
#Set timezone
if [ -z "$cityTimezone" ]; then
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$countryTimezone" /etc/localtime
else
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$countryTimezone"/"$cityTimezone" /etc/localtime
fi


###LOCALE AND CLOCK###
#Set clock
sed "s,\#$locale,$locale,g" -i /mnt/etc/locale.gen
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring system..." \
--prgbox "Setting locale and system clock" "arch-chroot /mnt locale-gen && arch-chroot /mnt hwclock --systohc" "$HEIGHT" "$WIDTH"
#Set language
lang=$(echo "$locale" | cut -d ' ' -f 1)
echo "LANG=$lang" >> /mnt/etc/locale.conf
clear


###KEYMAP###
echo "KEYMAP=$keymap" > /mnt/etc/vconsole.conf


###HOSTNAME AND HOST FILE###
#Set hostname
echo "$host" >> /mnt/etc/hostname
#Set hostname and ip stuffs to /etc/hosts. This is from hblock
cat << EOF > /mnt/etc/hosts
127.0.0.1       localhost $host
255.255.255.255 broadcasthost
::1             localhost $host
::1             ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
ff02::3         ip6-allhosts
EOF


###REPO AND KEY SETUP###
#Install repos to target - multilib, aurmageddon, archlinuxcn
cat << EOF >> /mnt/etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist

#wailord284 custom repo with many aur packages used by Alexs Arch Linux Installer
#https://wailord284.club/repo/aurmageddon/x86_64/
[aurmageddon]
Server = https://wailord284.club/repo/\$repo/\$arch
SigLevel = Never

#China archlinux repo with many aur packages
[archlinuxcn]
Server = https://mirrors.xtom.us/archlinuxcn/\$arch
Server = https://mirrors.ocf.berkeley.edu/archlinuxcn/\$arch
Server = https://repo.archlinuxcn.org/\$arch
Server = https://cdn.repo.archlinuxcn.org/\$arch
SigLevel = Never

EOF
#Add the ubuntu and MIT keyserver to gpg. This works a lot better than the default ones
echo "keyserver keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
echo "keyserver hkp://pgp.mit.edu:11371" >> /mnt/etc/pacman.d/gnupg/gpg.conf
#Sign the chaotic-aur key
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing keys" \
--prgbox "Installing Chaotic-aur keyring" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com && arch-chroot /mnt pacman-key --lsign-key FBA220DFC880C036 && arch-chroot /mnt pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm" "$HEIGHT" "$WIDTH"
clear
#Reinstall keyring in case of gpg errors and add archlinuxcn/chaotic keyrings
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing keys" \
--prgbox "Installing Archlinuxcn keyring" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman -S archlinux-keyring archlinuxcn-keyring --noconfirm" "$HEIGHT" "$WIDTH"
clear


###PACKAGE INSTALLATION###
#Install desktop and software
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing desktop software" \
--prgbox "Installing desktop environment" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman -S --needed wget nano xfce4-panel xfce4-whiskermenu-plugin xfce4-taskmanager xfce4-cpufreq-plugin xfce4-pulseaudio-plugin xfce4-sensors-plugin xfce4-screensaver thunar-archive-plugin dialog network-manager-applet nm-connection-editor networkmanager-openvpn networkmanager xfce4 yay grub-customizer baka-mplayer gparted gnome-disk-utility thunderbird xfce4-terminal file-roller lzip lzop cpio zip unzip htop libreoffice-fresh hunspell-en_US jre-openjdk jdk-openjdk zafiro-icon-theme deluge-gtk bleachbit galculator geeqie mpv mousepad papirus-icon-theme ttf-ubuntu-font-family ttf-ibm-plex bash-completion pavucontrol redshift yt-dlp ffmpeg atomicparsley openssh gvfs-mtp cpupower ttf-dejavu ttf-liberation noto-fonts pulseaudio-alsa xfce4-notifyd xfce4-screenshooter dmidecode macchanger smartmontools neofetch net-tools xorg-xev dnsmasq downgrade nano-syntax-highlighting s-tui imagemagick libxpresent freetype2 rsync screen acpi keepassxc xclip noto-fonts-emoji unrar bind-tools arch-install-scripts earlyoom arc-gtk-theme xorg-xrandr iotop libva-mesa-driver mesa-vdpau libva-vdpau-driver libvdpau-va-gl vdpauinfo libva-utils gpart pinta irqbalance xf86-video-fbdev xf86-video-amdgpu xf86-video-ati xf86-video-nouveau vulkan-icd-loader firefox hdparm usbutils logrotate ethtool systembus-notify dbus-broker tldr kitty vnstat kernel-modules-hook mlocate libopenraw gtk-engine-murrine gvfs-smb mesa-utils xorg-xkill f2fs-tools xorg-xhost exfatprogs gsmartcontrol remmina libvncserver freerdp nmap profile-sync-daemon reflector ntfs-3g lsscsi lightdm lightdm-gtk-greeter xorg fsearch --noconfirm" "$HEIGHT" "$WIDTH"
clear
#Additional aurmageddon packages
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional desktop software" \
--prgbox "Installing Aurmageddon packages" "arch-chroot /mnt pacman -S ttf-symbola surfn-icons-git pokemon-colorscripts-git arch-silence-grub-theme-git bibata-cursor-translucent usbimager matcha-gtk-theme nordic-theme nordic-darker-standard-buttons-theme pacman-cleanup-hook ttf-unifont lscolors-git zramswap preload skeuos-gtk pacman-updatedb-hook graphite-gtk-theme-nord-rimless-compact-git needrestart --noconfirm" "$HEIGHT" "$WIDTH"
clear


###SETUP CHAOTIC-AUR REPO###
#Add chaotic-aur and to pacman.conf. Currently nothing is installed from this unless user wants a custom kernel
cat << EOF >> /mnt/etc/pacman.conf
#Chaotic-aur repo with many packages
[chaotic-aur]
SigLevel = PackageOptional
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
#Update repos on the ISO and the target
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Updating repos" \
--prgbox "Updating pacman repos for chaotic-aur" "arch-chroot /mnt pacman -Syy && pacman -Syy" "$HEIGHT" "$WIDTH"
clear


###INSTALL CUSTOM KERNEL###
#If user wants a custom kernel, install it here. For some reason, we need to echo the variables otherwise it doesnt work with pacman
if [ "$kernel" = y ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Custom kernel" \
	--prgbox "Installing custom kernel and headers" "arch-chroot /mnt pacman -S $(echo $installKernel $installKernelHeaders) --noconfirm" "$HEIGHT" "$WIDTH"
fi
clear


###CORE SYSTEM SERVICES###
#Enable services
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Enabling Services" \
--prgbox "Enabling core system services" "arch-chroot /mnt systemctl enable NetworkManager systemd-timesyncd ctrl-alt-del.target earlyoom zramswap lightdm linux-modules-cleanup logrotate.timer" "$HEIGHT" "$WIDTH"
clear
#Enable fstrim if an ssd is detected using lsblk -d -o name,rota. Will return 0 for ssd
#This works however if you install via usb itll detect the usb drive as nonrotational and enable fstrim
if lsblk -d -o name,rota | grep "0" > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Enabling FSTrim timer" \
	--prgbox "Enable FStrim" "arch-chroot /mnt systemctl enable fstrim.timer" "$HEIGHT" "$WIDTH"
fi
clear
#Enable performance services if RAM is over ~2GB
ramTotal=$(grep MemTotal /proc/meminfo | grep -Eo '[0-9]*')
if [ "$ramTotal" -gt "2000000" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Enabling Performance Services" \
	--prgbox "Enabling prelock, preload and irqbalance" "arch-chroot /mnt systemctl enable preload.service irqbalance && arch-chroot /mnt systemctl --global enable psd.service" "$HEIGHT" "$WIDTH"
fi
clear
#Dbus-broker setup. Disable dbus and then enable dbus-broker. systemctl --global enables dbus-broker for all users
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Enabling Services" \
--prgbox "Enabling dbus-broker" "arch-chroot /mnt systemctl disable dbus.service && arch-chroot /mnt systemctl enable dbus-broker.service && arch-chroot /mnt systemctl --global enable dbus-broker.service" "$HEIGHT" "$WIDTH"


###GPU CHECK/SETUP###
#Determine installed GPU - by default we now install the stuff required for AMD/Intel since those just autoload drivers
#The below stuff is now set to install vulkan drivers and hardware decoding for correct hardware
if lshw -class display | grep "Advanced Micro Devices" || dmesg | grep amdgpu > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found AMD Graphics card" "arch-chroot /mnt pacman -S opencl-mesa vulkan-radeon radeontop --noconfirm" "$HEIGHT" "$WIDTH"
fi
if lshw -class display | grep "Intel Corporation" || dmesg | grep "i915" > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found Intel Graphics card" "arch-chroot /mnt pacman -S vulkan-intel libva-intel-driver intel-media-driver intel-gpu-tools --noconfirm" "$HEIGHT" "$WIDTH"
fi
clear


###B43 FIRMWARE CHECK/SETUP###
#Detect b43 firmware wifi cards and install b43-firmware
if dmesg | grep -q 'b43-phy0 ERROR'; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found B43 Broadcom Wireless card" "arch-chroot /mnt pacman -S b43-firmware --noconfirm" "$HEIGHT" "$WIDTH"
fi


###AMD RYZEN ZENPOWER KERNEL DRIVER###
#Checks to see if the current CPU is ryzen. If it is, install a better temperature kernel driver that supports more values and readouts
CPUModel=$(lscpu | grep -io ryzen)
if [[ "$CPUModel" = Ryzen ]] || [[ "$CPUModel" = ryzen ]]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found AMD Ryzen CPU" "arch-chroot /mnt pacman -S zenpower3-dkms zenmonitor3-git --noconfirm" "$HEIGHT" "$WIDTH"
	#Prevent k10temp from loading and replace it with zenpower
	echo "blacklist k10temp" > /mnt/etc/modprobe.d/disable-k10temp.conf
	echo "zenpower" > /mnt/etc/modules-load.d/zenpower.conf
fi


###ZRAM###
#Changes the default amount of zram from 20% to 10% of total system RAM
sed "s,20,10,g" -i /mnt/etc/zramswap.conf


###NANO SETUP###
#Setup nano config
sed "s,\#\ set linenumbers, set linenumbers,g" -i /mnt/etc/nanorc
sed "s,\#\ set positionlog, set positionlog,g" -i /mnt/etc/nanorc
sed "s,\#\ set constantshow, set constantshow,g" -i /mnt/etc/nanorc
sed "s,\#\ set titlecolor bold\,white\,blue, set titlecolor bold\,lightwhite,g" -i /mnt/etc/nanorc
sed "s,\#\ set promptcolor lightwhite\,grey, set promptcolor lightwhite\,lightblack,g" -i /mnt/etc/nanorc
sed "s,\#\ set errorcolor bold\,white\,red, set errorcolor bold\,lightwhite\,red,g" -i /mnt/etc/nanorc
sed "s,\#\ set spotlightcolor black\,lightyellow, set spotlightcolor black\,lime,g" -i /mnt/etc/nanorc
sed "s,\#\ set selectedcolor lightwhite\,magenta, set selectedcolor lightwhite\,magenta,g" -i /mnt/etc/nanorc
sed "s,\#\ set stripecolor \,yellow, set stripecolor yellow,g" -i /mnt/etc/nanorc
sed "s,\#\ set statuscolor bold\,white\,green, set statuscolor bold\,white,g" -i /mnt/etc/nanorc
sed "s,\#\ set scrollercolor cyan, set scrollercolor cyan,g" -i /mnt/etc/nanorc
sed "s,\#\ set numbercolor cyan, set numbercolor magenta,g" -i /mnt/etc/nanorc
sed "s,\#\ set keycolor cyan, set keycolor cyan,g" -i /mnt/etc/nanorc
sed "s,\#\ set functioncolor green, set functioncolor green,g" -i /mnt/etc/nanorc
sed "s,\#\ include \"/usr/share/nano/\*.nanorc\", include \"/usr/share/nano/\*.nanorc\",g" -i /mnt/etc/nanorc
echo "include /usr/share/nano-syntax-highlighting/*.nanorc" >> /mnt/etc/nanorc


###PULSEAUDIO SETUP###
#Change pulseaudio to have higher priority and enable realtime priority
sed "s,\; high-priority = yes,high-priority = yes,g" -i /mnt/etc/pulse/daemon.conf
sed "s,\; nice-level = -11,nice-level = -11,g" -i /mnt/etc/pulse/daemon.conf
sed "s,\; realtime-scheduling = yes,realtime-scheduling = yes,g" -i /mnt/etc/pulse/daemon.conf
sed "s,\; realtime-priority = 5,realtime-priority = 5,g" -i /mnt/etc/pulse/daemon.conf


###SUDO SETUP###
#Add sudo changes
sed "s,\#\ %wheel ALL=(ALL:ALL) ALL,%wheel ALL=(ALL:ALL) ALL,g" -i /mnt/etc/sudoers
cat << EOF >> /mnt/etc/sudoers
Defaults timestamp_type=global
Defaults passwd_tries=5
Defaults passwd_timeout=0
Defaults env_reset,pwfeedback
Defaults editor=/usr/bin/rnano
Defaults log_host, log_year, logfile="/var/log/sudo.log"
#Required for profile-sync-daemon when using overlayfs
$user ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper
#Uncomment to allow some commands to be executed without entering the user password
#$user ALL=(ALL) NOPASSWD:/usr/bin/pacman,/usr/bin/yay,/usr/bin/cpupower,/usr/bin/iotop,/usr/bin/poweroff,/usr/bin/reboot,/usr/bin/machinectl,/usr/bin/reflector,/usr/bin/dmesg"
EOF


###MAKEPKG SETUP###
#Setup makepkg config
#Change default -j count to use all cores
sed "s,\#\MAKEFLAGS=\"-j2\",MAKEFLAGS=\"-j\$(nproc)\",g" -i /mnt/etc/makepkg.conf
#Build all pkgs with native optimizations
sed "s,-mtune=generic,-mtune=native,g" -i /mnt/etc/makepkg.conf
#Enable link time optimizations
sed "s,\!lto,lto,g" -i /mnt/etc/makepkg.conf
#Build all rust pkgs with native optimizations
sed "s,\#\RUSTFLAGS=\"-C opt-level=2\",RUSTFLAGS=\"-C opt-level=2 -C target-cpu=native\",g" -i /mnt/etc/makepkg.conf
#Enable multithreaded compression support
sed "s,COMPRESSGZ=(gzip -c -f -n),COMPRESSGZ=(pigz -c -f -n),g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSBZ2=(bzip2 -c -f),COMPRESSBZ2=(pbzip2 -c -f),g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSXZ=(xz -c -z -),COMPRESSXZ=(xz -e -9 -c -z --threads=0 -),g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSZST=(zstd -c -z -q -),COMPRESSZST=(zstd -c --ultra -22 --threads=0 -),g" -i /mnt/etc/makepkg.conf
#Change default pkg extension to just tar (uncompressed)
sed "s,PKGEXT='.pkg.tar.zst',PKGEXT='.pkg.tar',g" -i /mnt/etc/makepkg.conf


###VIRTUAL MACHINE CHECK/SETUP###
#Detect if running in virtual machine and install guest additions
#$product - Sets to company that produces the system
#$hypervisor - Name of hypervisor software (extra check if dmidecode fails)
#$manufacturer - Systemd has built in tools to check for VM (extra extra check)
product=$(dmidecode -s system-product-name)
hypervisor=$(dmesg | grep "Hypervisor detected" | cut -d ":" -f 2 | tr -d ' ')
manufacturer=$(systemd-detect-virt)
if [ "$product" = "VirtualBox" ] || [ "$hypervisor" = "VirtualBox" ] || [ "$manufacturer" = "oracle" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting virtual machine" \
	--prgbox "Running in VirtualBox - Installing guest additions" "arch-chroot /mnt pacman -S xf86-video-vmware virtualbox-guest-utils --noconfirm" "$HEIGHT" "$WIDTH"
elif [ "$product" = "Standard PC (Q35 + ICH9, 2009)" ] || [ "$hypervisor" = "KVM" ] || [ "$manufacturer" = "kvm" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting virtual machine" \
	--prgbox "Running in KVM - Installing guest additions" "arch-chroot /mnt pacman -S qemu-guest-agent spice spice-vdagent xf86-video-qxl --noconfirm && arch-chroot /mnt systemctl enable qemu-guest-agent.service" "$HEIGHT" "$WIDTH"
elif [ "$product" = "VMware Virtual Platform" ] || [ "$hypervisor" = "VMware" ] || [ "$manufacturer" = "vmware" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting virtual machine" \
	--prgbox "Running in VMWare - Installing guest additions" "arch-chroot /mnt pacman -S xf86-video-vmware xf86-input-vmmouse open-vm-tools --noconfirm && arch-chroot /mnt systemctl enable vmtoolsd.service vmware-vmblock-fuse.service" "$HEIGHT" "$WIDTH"
fi
clear


###USER CONFIG SETUP - /etc/skel###
#Download config files from github
configFiles=Alexs-Arch-Installer-master
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring system" \
--prgbox "Downloading config files" "wget https://github.com/wailord284/Alexs-Arch-Installer/archive/master.zip && unzip master.zip && rm -r master.zip" "$HEIGHT" "$WIDTH"
#Create /etc/skel dirs for configs to be applied to our new user
mkdir -p /mnt/etc/skel/.config/{gtk-3.0,gtk-2.0,readline,kitty,screen,wezterm,psd,htop,dconf}
mkdir -p /mnt/etc/skel/.mozilla/
#Move profile-sync-daemon config
mv "$configFiles"/configs/psd.conf /mnt/etc/skel/.config/psd/
#Move kitty config
mv "$configFiles"/configs/kitty.conf /mnt/etc/skel/.config/kitty/
#Move wezterm config. We dont install wezterm by default
mv "$configFiles"/configs/wezterm.lua /mnt/etc/skel/.config/wezterm/
#Move gtk-2.0 disable recents
mv "$configFiles"/configs/gtk-2.0/gtkrc /mnt/etc/skel/.config/gtk-2.0/
#Move gtk-3.0 disable recents
mv "$configFiles"/configs/gtk-3.0/settings.ini /mnt/etc/skel/.config/gtk-3.0/
#Move the xfce configs
mv "$configFiles"/configs/xfce4/ /mnt/etc/skel/.config/
#Move the mousepad config in dconf
mv "$configFiles"/configs/dconf/user /mnt/etc/skel/.config/dconf/
#Move mimelist - sets some default apps for file types
mv "$configFiles"/configs/mimeapps.list /mnt/etc/skel/.config/
#Move htoprc
mv "$configFiles"/configs/htoprc /mnt/etc/skel/.config/htop/
#Bash stuff and screenrc
mv "$configFiles"/configs/bash/inputrc /mnt/etc/skel/.config/readline/
mv "$configFiles"/configs/bash/screenrc /mnt/etc/skel/.config/screen/
mv "$configFiles"/configs/bash/.bashrc /mnt/etc/skel/
#Move Firefox config
mv "$configFiles"/configs/firefox/ /mnt/etc/skel/.mozilla/


###USER, PASSWORDS and PAM###
#Create autologin group for lightdm
arch-chroot /mnt groupadd -r autologin
#Add user here to get /etc/skel configs
arch-chroot /mnt useradd -m -G network,kvm,floppy,disk,storage,uucp,wheel,optical,video,autologin -s /bin/bash "$user"
#Create a temp file to store the password in
TMPFILE=$(mktemp)
#Setup more secure passwd by increasing hashes
sed '/nullok/d' -i /mnt/etc/pam.d/passwd
echo "password required pam_unix.so sha512 shadow nullok rounds=65536" >> /mnt/etc/pam.d/passwd
#Create account passwords
echo "$user":"$pass" > "$TMPFILE"
arch-chroot /mnt chpasswd < "$TMPFILE"
#Set the root password
echo "root":"$pass" > "$TMPFILE"
arch-chroot /mnt chpasswd < "$TMPFILE"
#Unset and delete the passwords stored in pass1 pass2 pass and encpass encpass1 encpass2
unset pass1 pass2 pass encpass encpass1 encpass2
rm -rf "$TMPFILE"
#Setup stronger password security by increasing delay between password attempts to 4 seconds
echo "auth optional pam_faildelay.so delay=4000000" >> /mnt/etc/pam.d/system-login
#Require users to be in the wheel group to run su
echo "auth required pam_wheel.so use_uid" >> /mnt/etc/pam.d/su
echo "auth required pam_wheel.so use_uid" >> /mnt/etc/pam.d/su-l
#Remove annoying systemd-homed log messages anytime sudo is used
sed "s/success=2/success=1/g" -i /mnt/etc/pam.d/system-auth


###FONTS###
#Set fonts
#https://www.reddit.com/r/archlinux/comments/5r5ep8/make_your_arch_fonts_beautiful_easily/
arch-chroot /mnt ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/10-hinting-full.conf /etc/fonts/conf.d
sed "s,\#export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",g" -i /mnt/etc/profile.d/freetype2.sh


###XORG###
#Add xorg file that allows the user to press control + alt + backspace to kill xorg (returns to login manager)
mv "$configFiles"/configs/xorg/90-zap.conf /mnt/etc/X11/xorg.conf.d/


###ENVIRONMENT VARIABLES###
#These variables help enforce config files out of the home directory
mv "$configFiles"/configs/xdg.sh /mnt/etc/profile.d/


###NETWORK MANAGER###
#NetworkManager/Network startup scripts
mkdir -p /mnt/etc/NetworkManager/conf.d/
mkdir -p /mnt/etc/NetworkManager/dnsmasq.d/
#Configure mac address spoofing on startup via networkmanager. Only wireless interfaces are randomized
mv "$configFiles"/configs/networkmanager/rand_mac.conf /mnt/etc/NetworkManager/conf.d/
#IPv6 privacy and managed connection
cat << EOF >> /mnt/etc/NetworkManager/NetworkManager.conf
[connection]
ipv6.ip6-privacy=2
[ifupdown]
managed=true
EOF
#Use dnsmasq for dns - networkmanager sets dns in resolv.conf to 127.0.0.1 when dns=dnsmasq
mv "$configFiles"/configs/networkmanager/dns.conf /mnt/etc/NetworkManager/conf.d/
echo "cache-size=1000" > /mnt/etc/NetworkManager/dnsmasq.d/cache.conf
echo "listen-address=::1" > /mnt/etc/NetworkManager/dnsmasq.d/ipv6_listen.conf
mv "$configFiles"/configs/networkmanager/dnssec.conf /mnt/etc/NetworkManager/dnsmasq.d/
#Set default DNS to cloudflare and dns.sb
mv "$configFiles"/configs/networkmanager/dns-servers.conf /mnt/etc/NetworkManager/conf.d/
#Set network manager to avoid systemd-resolved. Fixes issue "unit dbus-org.freedesktop.resolve1.service not found" in journal log
mv "$configFiles"/configs/networkmanager/no-systemd-resolve.conf /mnt/etc/NetworkManager/conf.d/


###UDEV RULES###
#IOschedulers for storage that supposedly increase perfomance
mv "$configFiles"/configs/udev/60-ioschedulers.rules /mnt/etc/udev/rules.d/
#HDParm rule to spin down drives after 20 idle minutes
mv "$configFiles"/configs/udev/69-hdparm.rules /mnt/etc/udev/rules.d/


###POLKIT RULES###
#Add polkit rule so users in KVM group can use libvirt (you don't need to be in the libvirt group now)
mv -f "$configFiles"/configs/polkit-1/50-libvirt.rules /mnt/etc/polkit-1/rules.d/
#Add gparted polkit rule for storage group, allow users to not enter a password
mv -f "$configFiles"/configs/polkit-1/00-gparted.rules /mnt/etc/polkit-1/rules.d/
#Add gsmartcontrol rule for storage group, allow users to not enter a password to view smart data
mv -f "$configFiles"/configs/polkit-1/50-gsmartcontrol.rules /mnt/etc/polkit-1/rules.d/
#Allow user in the network group to add/modify/delete networks without a password
mv -f "$configFiles"/configs/polkit-1/50-networkmanager.rules /mnt/etc/polkit-1/rules.d/


###SCRIPTS###
mkdir -p /mnt/opt/scripts/
mv "$configFiles"/configs/scripts/* /mnt/opt/scripts/


###PACMAN HOOKS###
#Add the needrestart pacman hook
mkdir -p /mnt/etc/pacman.d/hooks/
mv "$configFiles"/configs/pacman-hooks/needrestart.hook /mnt/etc/pacman.d/hooks/
mv "$configFiles"/configs/pacman-hooks/update-grub.hook /mnt/etc/pacman.d/hooks/
clear


###WACOM TABLET###
#Change to and if -d /proc/bus/input/devices/wacom
#Check and setup touchscreen - like x201T/x220T
if grep -i wacom /proc/bus/input/devices > /dev/null 2>&1 ; then
	mv "$configFiles"/configs/xorg/72-wacom-options.conf /mnt/etc/X11/xorg.conf.d/
fi


###LAPTOP SETUP###
#Check and setup laptop features
if acpi -V | grep -iq Battery ; then acpiBattery=yes; fi
if [ -d "/sys/class/power_supply/BAT0" ] || [ -d "/sys/class/power_supply/BAT1" ]; then sysBattery=yes; fi
modelType=$(hostnamectl | sed 's/ //g' | grep "HardwareModel" | cut -d":" -f2)
if [ "$modelType" = Laptop ] || [ "$acpiBattery" = yes ] || [ "$sysBattery" = yes ]; then
	#Move the powertop auto tune service so it can be enabled
	mv "$configFiles"/configs/systemd/powertop.service /mnt/etc/systemd/system/
	#Install power saving tools and enable tlp, powertop and other power saving tweaks
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Laptop Found" \
	--prgbox "Setting up powersaving features" "arch-chroot /mnt pacman -S powertop x86_energy_perf_policy xf86-input-synaptics tlp tlp-rdw --noconfirm && arch-chroot /mnt systemctl enable tlp.service" "$HEIGHT" "$WIDTH"
	#Add touchpad config
	mv "$configFiles"/configs/xorg/70-synaptics.conf /mnt/etc/X11/xorg.conf.d/
	#Laptop mode
	mv "$configFiles"/configs/sysctl/00-laptop-mode.conf /mnt/etc/sysctl.d/
	#Disable watchdog - may help with power
	mv "$configFiles"/configs/sysctl/10-disable-watchdog.conf /mnt/etc/sysctl.d/
	#Set PCIE powersave in TLP
	sed "s,\#\PCIE_ASPM_ON_BAT=default,PCIE_ASPM_ON_BAT=powersupersave,g" -i /mnt/etc/tlp.conf
	#Mask rfkill for TLP
	arch-chroot /mnt systemctl mask systemd-rfkill.socket systemd-rfkill.service > /dev/null 2>&1
	#Increase dirty writeback time to 60 seconds - same as TLP
	mv "$configFiles"/configs/sysctl/50-dirty-writebacks.conf /mnt/etc/sysctl.d/
	#Disable wake on lan - may help with power savings
	mv "$configFiles"/configs/udev/81-disable_wol.rules /mnt/etc/udev/rules.d/
	mv "$configFiles"/configs/networkmanager/wake-on-lan.conf /mnt/etc/NetworkManager/conf.d/
	#Enable wifi powersaving
	mv "$configFiles"/configs/udev/81-wifi-powersave.rules /mnt/etc/udev/rules.d/
fi
clear


###FILESYSTEM - BTRFS###
#If we have a BTRFS filesystem, add some extra software and configs
if [ "$filesystem" = btrfs ] ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Installing Additional Software" \
	--prgbox "Adding configs and software for BTRFS" "arch-chroot /mnt pacman -S grub-btrfs snap-pac-grub snapper snap-pac btrfs-assistant --noconfirm" "$HEIGHT" "$WIDTH"
	#Make locate not index .snapshots directory
	sed "s,PRUNENAMES = \".git .hg .svn\",PRUNENAMES = \".git .hg .svn .snapshots\",g" -i /mnt/etc/updatedb.conf
	#Change the snapper-cleanup timer run every six hours instead of once per day
	sed "s,1d,6h,g" -i /mnt/usr/lib/systemd/system/snapper-cleanup.timer
	#Add the fristboot systemd script for snapper and enable the monthly btrfs scrub timer
	mv "$configFiles"/configs/systemd/snapper-firstboot.service /mnt/etc/systemd/system/
	arch-chroot /mnt systemctl enable snapper-firstboot.service btrfs-scrub@-.timer > /dev/null 2>&1
	#Move and enable the BTRFS defrag service and timer
	mv "$configFiles"/configs/systemd/btrfs-autodefrag.service /mnt/etc/systemd/system/
	mv "$configFiles"/configs/systemd/btrfs-autodefrag.timer /mnt/etc/systemd/system/
	arch-chroot /mnt systemctl enable btrfs-autodefrag.timer > /dev/null 2>&1
	#Update mkinitcpio to include btrfs hooks for Grub. Get the current hooks then add grub-btrfs-overlayfs
	currentHooks=$(tac /mnt/etc/mkinitcpio.conf | grep -m1 HOOKS=)
	newHooks=$(tac /mnt/etc/mkinitcpio.conf | grep -m1 HOOKS= | sed 's/.\{1\}$//' | sed -e 's/$/ grub-btrfs-overlayfs)/g')
	#Replace the currentHooks with newHooks (appends grub-btrfs-overlayfs to the end)
	sed "s,$currentHooks,$newHooks,g" -i /mnt/etc/mkinitcpio.conf
	#Add btrfs assistant rule for storage group, allow users to not enter a password to view smart data
	mv -f "$configFiles"/configs/polkit-1/50-btrfsassistant.rules /mnt/etc/polkit-1/rules.d/
	clear
fi


###MODULES###
#Load the tcp_bbr module for better networking. This is utilized in the network sysctl config
echo 'tcp_bbr' > /mnt/etc/modules-load.d/tcp_bbr.conf


###LGIHTDM - DISPLAY MANAGER###
#Set greeter
sed "s,\#greeter-session=example-gtk-gnome,greeter-session=lightdm-gtk-greeter,g" -i /mnt/etc/lightdm/lightdm.conf
#Remove xauth dot file from /home/user/
sed "s,\#user-authority-in-system-dir=false,user-authority-in-system-dir=true,g" -i /mnt/etc/lightdm/lightdm.conf
#Background
sed "s,\#background=,background=\#2b303c,g" -i /mnt/etc/lightdm/lightdm-gtk-greeter.conf
#Icons
sed "s,\#icon-theme-name=,icon-theme-name=zafiro-dark,g" -i /mnt/etc/lightdm/lightdm-gtk-greeter.conf
#Theme
sed "s,\#theme-name=,theme-name=Matcha-dark-azul,g" -i /mnt/etc/lightdm/lightdm-gtk-greeter.conf


###SYSTEMD###
#Systemd service for packet sniffing. Not enabled
mv "$configFiles"/configs/systemd/promiscuous@.service /mnt/etc/systemd/system/
#Set journal to output log contents to TTY12
mkdir /mnt/etc/systemd/journald.conf.d
mv "$configFiles"/configs/systemd/fw-tty12.conf /mnt/etc/systemd/journald.conf.d/
#Set a lower systemd timeout
sed "s,\#\DefaultTimeoutStartSec=90s,DefaultTimeoutStartSec=45s,g" -i /mnt/etc/systemd/system.conf
sed "s,\#\DefaultTimeoutStopSec=90s,DefaultTimeoutStopSec=45s,g" -i /mnt/etc/systemd/system.conf
#Set journal to only keep 1024MB of logs
mv "$configFiles"/configs/systemd/00-journal-size.conf /mnt/etc/systemd/journald.conf.d/
#Copy and enable the clear-pacman-cache service and timer
mv "$configFiles"/configs/systemd/clear-pacman-cache.timer /mnt/etc/systemd/system/
mv "$configFiles"/configs/systemd/clear-pacman-cache.service /mnt/etc/systemd/system/
#Add the TTY Interfaces service to output interface IP addresses to the TTY login screen
mv "$configFiles"/configs/systemd/ttyinterfaces.service /mnt/etc/systemd/system/
#Enable the clear-pacman-cache service and ttyinterfaces.service
arch-chroot /mnt systemctl enable clear-pacman-cache.timer ttyinterfaces.service > /dev/null 2>&1


###SYSCTL RULES###
#Provide the ability to allow unprivileged_userns_clone for programs like Zoom
mv "$configFiles"/configs/sysctl/00-unprivileged-userns.conf /mnt/etc/sysctl.d/
#OOM Killer tweaks
mv "$configFiles"/configs/sysctl/00-oom-killer.conf /mnt/etc/sysctl.d/
#Low-level console messages
mv "$configFiles"/configs/sysctl/10-console-messages.conf /mnt/etc/sysctl.d/
#IPv6 privacy
mv "$configFiles"/configs/sysctl/10-ipv6-privacy.conf /mnt/etc/sysctl.d/
#Kernel hardening
mv "$configFiles"/configs/sysctl/10-kernel-hardening.conf /mnt/etc/sysctl.d/
#System tweaks
mv "$configFiles"/configs/sysctl/30-system-tweak.conf /mnt/etc/sysctl.d/
#Network tweaks
mv "$configFiles"/configs/sysctl/30-network.conf /mnt/etc/sysctl.d/
#RAM and storage tweaks
mv "$configFiles"/configs/sysctl/50-dirty-bytes.conf /mnt/etc/sysctl.d/


###GRUB INSTALL###
#Grub install - support uefi 64 and 32
if [ "$boot" = efi ]; then
	if [ "$bootArch" = 64 ]; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "GRUB installation" \
		--prgbox "Installing grub for UEFI" "arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable --recheck" "$HEIGHT" "$WIDTH"
	else
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "GRUB installation" \
		--prgbox "Installing grub for 32 bit UEFI" "arch-chroot /mnt grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=GRUB --removable --recheck" "$HEIGHT" "$WIDTH"
	fi
fi
if [ "$boot" = bios ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "GRUB installation" \
	--prgbox "Installing grub for legacy BIOS" "arch-chroot /mnt grub-install --target=i386-pc $storage --recheck" "$HEIGHT" "$WIDTH"
fi
clear


###GRUB MENUS###
#Add custom menus to grub
#Move grub boot items
mkdir -p /mnt/boot/EFI/tools
mkdir -p /mnt/boot/EFI/games
mv "$configFiles"/configs/grub/tools/* /mnt/boot/EFI/tools/
mv "$configFiles"/configs/grub/games/*.efi /mnt/boot/EFI/games/
mv "$configFiles"/configs/grub/custom.cfg /mnt/boot/grub/


###GRUB BOOT OPTIONS###
#Check the output of cat /sys/power/mem_sleep for the systems sleep mode
#If the system is using s2idle but also has deep sleep mode availible, switch it to deep
#This is especially needed on the Framework laptop, although others may benefit
#This setting does make the laptop take longer to wake from sleep, but reduces power consumption a decent bit
sleepMode=$(cat /sys/power/mem_sleep)
if [ "$sleepMode" = "[s2idle] deep" ]; then
	#If the system has both s2idle and deep but s2idle is currently selected, then deep sleep will be used
	#This will set mem_sleep_default=deep in grub - GRUB_CMDLINE_LINUX
	grubCmdlineLinuxOptions=mem_sleep_default=deep
fi
#If mitigations are wanted, add them as well as grubCmdlineLinuxOptions. If deep sleep was selected it will be added
if [ "$disableMitigations" = "y" ]; then
	grubCmdlineLinuxOptions="$grubSecurityMitigations $grubCmdlineLinuxOptions"
fi


###GRUB CONFIG###
#Generate grubcfg with root UUID if encrypt=y
if [ "$encrypt" = y ]; then
	rootTargetDiskUUID=$(lsblk -dno UUID "${storagePartitions[2]}")
	sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$rootTargetDiskUUID:cryptroot root=$rootTargetDisk audit=0 loglevel=3\",g" -i /mnt/etc/default/grub
fi
#Generate grubcfg if no encryption
if [ "$encrypt" = n ]; then
	sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"audit=0 loglevel=3\",g" -i /mnt/etc/default/grub
fi
#Append additional grub boot options if selected
if [ -z "$grubCmdlineLinuxOptions" ]; then
	true #Do nothing if unset
else
	#If set, add the options to grub
	sed "s,\GRUB_CMDLINE_LINUX=\"\",\GRUB_CMDLINE_LINUX=\"$grubCmdlineLinuxOptions\",g" -i /mnt/etc/default/grub
fi
#Change theme
echo 'GRUB_THEME="/boot/grub/themes/arch-silence/theme.txt"' >> /mnt/etc/default/grub
#Generate grubcfg
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring grub" \
--prgbox "Generating grubcfg" "arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg" "$HEIGHT" "$WIDTH"
clear


###MIRRORLIST SORTING - TARGET###
#Sort mirrors
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Sorting mirrors on target device" \
--prgbox "Please wait while mirrors are sorted" "reflector --download-timeout 10 --connection-timeout 10 --verbose -f 10 --latest 20 --country $region --protocol https --age 24 --sort rate --save /etc/pacman.d/mirrorlist" "$HEIGHT" "$WIDTH"
#Remove the following mirrors. For some reason they behave randomly
sed '/mirror.lty.me/d' -i /etc/pacman.d/mirrorlist
sed '/mirrors.kernel.org/d' -i /etc/pacman.d/mirrorlist
sed '/octyl.net/d' -i /etc/pacman.d/mirrorlist
clear


###POST INSTALL###
#Optional post install settings
declare -a selection
echo "$green""Installation complete! Here are some optional things you may want to install:""$reset"
echo "$green""1$reset - Install Bedrock Linux (Advanced users only!)"
echo "$green""2$reset - Enable X2Go remote desktop management server"
echo "$green""3$reset - Enable sshd"
echo "$green""4$reset - Enable and install the UFW firewall"
echo "$green""5$reset - Use the iwd wifi backend over wpa_suplicant for NetworkManager"
echo "$green""6$reset - Enable automatic desktop login in lightdm $green(recommended)"
echo "$green""7$reset - Block ads system wide using hblock to modify the hosts file $green(recommended)"
echo "$green""8$reset - Encrypt and cache DNS requests with dns-over-https"

echo "$reset""Default options are:$green 6 7$red q""$reset"
echo "Enter$green 1-8$reset (seperated by spaces for multiple options) or$red q$reset to$red quit$reset"
read -r -p "Options: " selection
selection=${selection:- 6 7 q}
	for entry in $selection ; do

	case "${entry[@]}" in

		1) #Bedrock Linux
		#https://raw.githubusercontent.com/bedrocklinux/bedrocklinux-userland/0.7/releases
		bedrockVersion="0.7.28"
		echo "$green""Installing Bedrock Linux""$reset"
		modprobe fuse
		arch-chroot /mnt wget https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/"$bedrockVersion"/bedrock-linux-"$bedrockVersion"-x86_64.sh
		arch-chroot /mnt sh bedrock-linux-"$bedrockVersion"-x86_64.sh --hijack
		arch-chroot /mnt sed "s,timeout = 30,timeout = 5,g" -i /bedrock/etc/bedrock.conf
		sleep 3s
		;;

		2) #X2Go
		echo "$green""Setting up X2Go server. Will also enable sshd.""$reset"
		arch-chroot /mnt pacman -S x2goserver x2goclient --noconfirm
		arch-chroot /mnt x2godbadmin --createdb
		arch-chroot /mnt systemctl enable x2goserver sshd
		sleep 3s
		;;

		3) #SSHD
		echo "$green""Enabling sshd""$reset" # AllowUsers, PermitRootLogin no
		arch-chroot /mnt systemctl enable sshd
		sleep 3s
		;;

		4) #UFW
		echo "$green""Installing and configuring the UFW firewall""$reset"
		arch-chroot /mnt pacman -S ufw gufw --noconfirm
		arch-chroot /mnt ufw default deny
		arch-chroot /mnt ufw allow deluge
		arch-chroot /mnt ufw limit SSH
		arch-chroot /mnt ufw enable
		arch-chroot /mnt systemctl enable ufw.service
		sleep 3s
		;;

		5) #IWD
		echo "$green""Configuring iwd as the default wifi backend in NetworkManager""$reset"
		arch-chroot /mnt pacman -S iwd --noconfirm
		mv "$configFiles"/configs/networkmanager/wifi_backend.conf /mnt/etc/NetworkManager/conf.d/
		sleep 3s
		;;

		6) #Desktop login - Lightdm
		echo "$green""Enabling automatic desktop login""$reset"
		sed "s,\#autologin-user=,autologin-user=$user,g" -i /mnt/etc/lightdm/lightdm.conf
		sed "s,\#autologin-session=,autologin-session=xfce,g" -i /mnt/etc/lightdm/lightdm.conf
		sleep 3s
		;;

		7) #hblock
		#run hblock to prevent ads
		echo "$green""Running hblock and enabling hblock.timer - hosts file will be modified""$reset"
		arch-chroot /mnt pacman -S hblock --noconfirm
		arch-chroot /mnt hblock
		arch-chroot /mnt systemctl enable hblock.timer
		#Make sure to replace the hostname from archiso
		sed -i "s/archiso/$host/g" /mnt/etc/hosts
		sleep 3s
		;;

		8) #Encrypt DNS - dns-over-https
		echo "$green""Setting up dns-over-https""$reset"
		arch-chroot /mnt pacman -S dns-over-https --noconfirm
		#Remove stock network manager configs and use 127.0.0.1 as the DNS server
		rm -r /mnt/etc/NetworkManager/dnsmasq.d/*
		rm -r /mnt/etc/NetworkManager/conf.d/dns-servers.conf
		rm -r /mnt/etc/NetworkManager/conf.d/dns.conf
		#Move new network manager dns configs
		mv "$configFiles"/configs/dns-https/dns-servers.conf /mnt/etc/NetworkManager/conf.d/
		mv "$configFiles"/configs/dns-https/dns.conf /mnt/etc/NetworkManager/conf.d/
		#Enable services
		arch-chroot /mnt systemctl enable doh-client.service
		sleep 3s
		;;

		q) #Finish
		#Unmount based on encryption
		if [ "$encrypt" = y ]; then
			umount -R /mnt
			umount -R /mnt/boot
			cryptsetup close cryptroot
		else
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
