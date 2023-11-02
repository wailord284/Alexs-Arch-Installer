#!/usr/bin/env bash
###ABOUT###
#Automated Arch Linux installation script by Alex aka "wailord284".
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
#Add chaotic-aur to live ISO pacman config
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
Server = https://ridgewireless.mm.fcix.net/archlinux/\$repo/os/\$arch
Server = https://mirror.arizona.edu/archlinux/\$repo/os/\$arch
Server = https://mirror.dal10.us.leaseweb.net/archlinux/\$repo/os/\$arch
Server = https://mirrors.sonic.net/archlinux/\$repo/os/\$arch
Server = https://archmirror1.octyl.net/\$repo/os/\$arch
Server = https://iad.mirrors.misaka.one/archlinux/\$repo/os/\$arch

EOF


###SET TIME AND CONFIGURE PACMAN###
#This is useful if you installed coreboot or have a dead RTC. The clock may have no time set by default and this will update it
timedatectl set-ntp true
#Sync repos and reinstall/install critical applications. Reinstalling glibc and the keyring helps fix errors if the ISO is outdated
#Also enable parallel downloads on the ISO to 3. Useful for the first pacstrap command
sed "s,\#\ParallelDownloads = 5,ParallelDownloads = 3,g" -i /etc/pacman.conf
pacman -Syy
pacman -S archlinux-keyring acpi glibc ntp ncurses unzip dmidecode wget dialog reflector python lshw --noconfirm
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
for i in $(tail -n+18 /etc/locale.gen | sed -e '/ISO-8859/d' -e 's/  $//' -e 's, ,+,g' -e 's,#,,g') ; do
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
#Check if device is an SSD. Make sure to get only the storage device without /dev/
storageDeviceType=$(echo $storage | cut -d"/" -f3)
if [ "$(cat /sys/block/$storageDeviceType/queue/rotational)" = 0 ]; then
	deviceUsesSSD=yes
else
	deviceUsesSSD=no
fi
clear


###DISK SPACE CHECK###
#Make sure the drive is at least 8GB (8589934592 bytes)
driveSize=$(fdisk -l /dev/sda | grep -m1 Disk | cut -d "," -f 2 | grep -Eo '[0-9]*')
if [ "$driveSize" -lt "8589934592" ]; then
	dialog --msgbox "Your target drive is smaller than 8GB. Please use a larger drive." "$dialogHeight" "$dialogWidth"
	exit 1
fi


###FILESYSTEM###
unset COUNT MENU_OPTIONS options
for i in $(echo "ext4 xfs btrfs f2fs"); do
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
	--yesno "$(printf %"s\n\n" "Do you want to enable disk encryption for the root partition?" "If you do not know what this means you can safely press no.")" "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
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
	--yesno "$(printf %"s\n\n" "Do you want to overwrite the drive with random data? This can take a long time depending on the size and speed of the drive." "This is also NOT recommended on any solid state media as it can shorten the devices life." "If you do not know what this means you can safely press no.")" "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
optionWipe=$?
if [ "$optionWipe" = 0 ]; then
	wipe="y"
else
	wipe="n"
fi
clear


###GRUB/SECURITY OPTIONS###
#Ask if user wants to disable security mitigations as well as trust cpu random
#We might add more performance options so lets make it a variable just in case
grubPerformanceOptions="mitigations=off nowatchdog quiet"
dialog --title "Performance Options" \
	--defaultno \
	--backtitle "$dialogBacktitle" \
	--yesno "$(printf %"s\n\n" "Do you want to disable spectre and meltdown mitigations? These options will improve performance at the cost of security. This is most impactful on systems older than 10th generation Intel or 1st generation AMD Ryzen processors." "This option will also disable Watchdog which can reduce power consumption and decrease boot times." "If you do not know what this means you can safely press no." "The following options will be added to Grub if you say yes and the grub timeout will be set to 1: $grubPerformanceOptions")" "$dialogHeight" "$dialogWidth" > /dev/tty 2>&1
optionEnableGrubPerformanceOptions=$?
if [ "$optionEnableGrubPerformanceOptions" = 0 ]; then
	enableGrubPerformanceOptions="y"
else
	enableGrubPerformanceOptions="n"
fi
clear


###FINAL CONFIRMATION###
#Ask the user if they want to continue with the current options
dialog --backtitle "$dialogBacktitle" \
--defaultno \
--title "Do you want to install with the following options?" \
--yesno "$(printf %"s\n" "Do you want to proceed with the installation? If you press yes, all data on the drive will be lost!" "Hostname: $host" "Username: $user" "Encryption: $encrypt" "Locale: $locale" "Keymap: $keymap" "Country Timezone: $countryTimezone" "City Timezone: $cityTimezone" "Mirrorlist location: $region" "Filesystem: $filesystem" "Install Disk: $storage" "Secure Wipe: $wipe" "Disable Mitigations: $enableGrubPerformanceOptions")" "$HEIGHT" "$WIDTH"
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
#Prepare to install. Detect efi/uefi or bios for GRUB
#If efi is present in /sys/firmware/ then system is UEFI
if [ -d /sys/firmware/efi/ ]; then
	boot="efi" #Set boot to efi
else
	boot="bios" #Set boot to bios
fi
#Also detect the boot arch. Some platforms have a 32bit UEFI (NOT to be confused with 32bit cpu)
if [ "$boot" = "efi" ]; then
	bootArch="$(cat /sys/firmware/efi/fw_platform_size)"
fi


###DISK PARTITIONING###
#Begin disk partitioning
#https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition
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
		#If encryption is set make rootTargetDisk the cryptroot mapper. Otherwise set it to ${storagePartitions[2]}
		rootTargetDisk=/dev/mapper/cryptroot
		#Run cryptsetup just in terminal. The password will be piped in from $encpass
		echo "$green""Setting up disk encryption. Please wait.""$reset"
		echo "$encpass" | cryptsetup --iter-time 5000 --use-urandom --type luks2 --cipher aes-xts-plain64 --key-size 512 --pbkdf argon2id luksFormat "${storagePartitions[2]}"
		#If the device is an SSD disable workqueue - https://wiki.archlinux.org/title/Dm-crypt/Specialties#Disable_workqueue_for_increased_solid_state_drive_(SSD)_performance
		if [ "$deviceUsesSSD" = yes ]; then
			echo "$encpass" | cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent open "${storagePartitions[2]}" cryptroot
			#Refresh the device to force the workqueue options
			echo "$encpass" | cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent refresh cryptroot
		else
			echo "$encpass" | cryptsetup open "${storagePartitions[2]}" cryptroot
		fi
	else
		#If encryption is not set make this set to ${storagePartitions[2]}
		rootTargetDisk="${storagePartitions[2]}"
	fi

	#Filesystem creation
	if [ "$filesystem" = ext4 ] ; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Patitioning Disk" \
		--prgbox "Formatting root partition" "mkfs.ext4 -O fast_commit -L ArchRoot $rootTargetDisk" "$HEIGHT" "$WIDTH"
	elif [ "$filesystem" = xfs ] ; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Patitioning Disk" \
		--prgbox "Formatting root partition" "mkfs.xfs -f -L ArchRoot $rootTargetDisk" "$HEIGHT" "$WIDTH"
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
		rootTargetDiskUUID=$(blkid | grep "$rootTargetDisk" | cut -d" " -f3 | cut -d'"' -f2)
		#Mount the root partition by UUID to make sure genfstab uses UUIDs
		mount -o noatime,compress-force=zstd:3,space_cache=v2,autodefrag,commit=90 -U "$rootTargetDiskUUID" /mnt
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
		mount -o noatime,compress-force=zstd:3,space_cache=v2,autodefrag,commit=90,subvol=@ -U "$rootTargetDiskUUID" /mnt
		#Make the subvolume directories to mount
		mkdir -p /mnt/{srv,var/log,var/cache,var/tmp,opt}
		#Mount the remaining subvoulmes
		mount -o noatime,compress-force=zstd:3,space_cache=v2,autodefrag,commit=90,subvol=@var_log -U "$rootTargetDiskUUID" /mnt/var/log
		mount -o noatime,compress-force=zstd:3,space_cache=v2,autodefrag,commit=90,subvol=@var_cache -U "$rootTargetDiskUUID" /mnt/var/cache
		mount -o noatime,compress-force=zstd:3,space_cache=v2,autodefrag,commit=90,subvol=@var_tmp -U "$rootTargetDiskUUID" /mnt/var/tmp
		mount -o noatime,compress-force=zstd:3,space_cache=v2,autodefrag,commit=90,subvol=@opt -U "$rootTargetDiskUUID" /mnt/opt
		mount -o noatime,compress-force=zstd:3,space_cache=v2,autodefrag,commit=90,subvol=@srv -U "$rootTargetDiskUUID" /mnt/srv
	elif [ "$filesystem" = f2fs ] ; then
		#Mount F2FS root partition
		mount -o compress_algorithm=zstd:6,compress_chksum,atgc,gc_merge,lazytime "$rootTargetDisk" /mnt
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
#Remove the following mirrors. For some reason they behave poorly
sed '/mirror.lty.me/d' -i /etc/pacman.d/mirrorlist
sed '/mirrors.kernel.org/d' -i /etc/pacman.d/mirrorlist
sed '/octyl.net/d' -i /etc/pacman.d/mirrorlist
sed '/arch.hu.fo/d' -i /etc/pacman.d/mirrorlist
clear


###BASE PACKAGE INSTALL#
#Install the base Archlinux system and packages
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing packages" \
--prgbox "Installing base and base-devel package groups" "pacstrap -K /mnt base --noconfirm" "$HEIGHT" "$WIDTH"
clear


###PACMAN CONFIG###
#Enable verbose output, parallel downloads and color in pacman.conf
sed "s,\#\VerbosePkgLists,VerbosePkgLists,g" -i /mnt/etc/pacman.conf
sed "s,\#\ParallelDownloads = 5,ParallelDownloads = 4,g" -i /mnt/etc/pacman.conf
sed "s,\#\Color,Color,g" -i /mnt/etc/pacman.conf


###KERNEL, FIRMWARE, BASE-DEVEL AND MICROCODE INSTALLATION###
#Install additional base Archlinux packages and kernel
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional base software" \
--prgbox "Installing base and base-devel package groups" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman -S base-devel linux linux-headers linux-firmware mkinitcpio grub efibootmgr dosfstools mtools btrfs-progs --noconfirm" "$HEIGHT" "$WIDTH"
#Install amd or intel ucode based on detected cpu
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
defaultMkinitcpioHooks=$(grep HOOKS= /mnt/etc/mkinitcpio.conf | tail -n1)
performanceMkinitcpioHooks="HOOKS=(systemd keyboard autodetect modconf kms sd-vconsole block filesystems fsck)"
sed "s,$defaultMkinitcpioHooks,$performanceMkinitcpioHooks,g" -i /mnt/etc/mkinitcpio.conf
#Enable encryption mkinitcpio hook if needed and revert back to base/udev hooks as using the systemd one required additional changes
if [ "$encrypt" = y ]; then
	encryptionMkinitcpioHooks="HOOKS=(base udev keyboard autodetect modconf kms keymap block encrypt filesystems fsck)"
	sed "s,$performanceMkinitcpioHooks,$encryptionMkinitcpioHooks,g" -i /mnt/etc/mkinitcpio.conf
fi
#Arch has now made ZSTD the default. LZ4 is slightly faster but uses more disk space
sed "s,\#\COMPRESSION=\"lz4\",COMPRESSION=\"lz4\",g" -i /mnt/etc/mkinitcpio.conf
#Enable max compression for LZ4 saving some extra space. LZ4 still decompresses the fastest
sed "s,\#\COMPRESSION_OPTIONS=(),COMPRESSION_OPTIONS=(-9),g" -i /mnt/etc/mkinitcpio.conf
#Enable module decompression
sed "s,\#\MODULES_DECOMPRESS=\"yes\",MODULES_DECOMPRESS=\"yes\",g" -i /mnt/etc/mkinitcpio.conf


###FSTAB###
#Create FSTAB
genfstab -U /mnt >> /mnt/etc/fstab


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
#Add the following pacman repos to the installtion: multilib, aurmageddon, archlinuxcn
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

EOF
#Reinstall keyring in case of gpg errors and add the archlinuxcn and chaotic keyrings
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing keys" \
--prgbox "Installing Archlinuxcn keyring" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman -S archlinux-keyring archlinuxcn-keyring --noconfirm" "$HEIGHT" "$WIDTH"
clear
#Add the Ubuntu and MIT keyserver to gpg. This works a lot better and faster than the default ones
echo "keyserver keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
echo "keyserver hkp://pgp.mit.edu:11371" >> /mnt/etc/pacman.d/gnupg/gpg.conf
#Import the chaotic-aur key
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing keys" \
--prgbox "Installing Chaotic-aur keyring" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com && arch-chroot /mnt pacman-key --lsign-key 3056513887B78AEB && arch-chroot /mnt pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm" "$HEIGHT" "$WIDTH"
clear


###PACKAGE INSTALLATION###
#Install desktop and software
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing desktop software" \
--prgbox "Installing desktop environment" "arch-chroot /mnt pacman -Syy && arch-chroot /mnt pacman -S --needed wget nano xfce4-panel xfce4-whiskermenu-plugin xfce4-taskmanager xfce4-cpufreq-plugin xfce4-pulseaudio-plugin xfce4-notifyd xfce4-screenshooter xfce4-sensors-plugin xfce4-terminal xfce4-screensaver thunar-archive-plugin dialog network-manager-applet nm-connection-editor networkmanager xfce4 grub-customizer gparted gnome-disk-utility thunderbird file-roller lzip lzop cpio zip unzip htop libreoffice-fresh hunspell-en_US jre-openjdk jdk-openjdk zafiro-icon-theme deluge-gtk bleachbit galculator geeqie mpv mousepad papirus-icon-theme ttf-ubuntu-font-family ttf-ibm-plex bash-completion pavucontrol yt-dlp ffmpeg atomicparsley openssh gvfs-mtp cpupower ttf-dejavu ttf-liberation noto-fonts pulseaudio-alsa dmidecode macchanger smartmontools neofetch xorg-xev dnsmasq nano-syntax-highlighting s-tui imagemagick libxpresent freetype2 rsync acpi keepassxc xclip noto-fonts-emoji unrar earlyoom arc-gtk-theme xorg-xrandr iotop libva-mesa-driver mesa-vdpau libva-vdpau-driver libvdpau-va-gl vdpauinfo libva-utils gpart pinta irqbalance xf86-video-fbdev xf86-video-amdgpu xf86-video-ati xf86-video-nouveau vulkan-icd-loader firefox firefox-ublock-origin firefox-decentraleyes hdparm usbutils logrotate systembus-notify dbus-broker tldr kitty vnstat kernel-modules-hook mlocate gtk-engine-murrine gvfs-smb mesa-utils xorg-xkill f2fs-tools xorg-xhost exfatprogs gsmartcontrol remmina libvncserver freerdp profile-sync-daemon reflector ntfs-3g lsscsi xorg-server greetd greetd-tuigreet fsearch xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-gtk --noconfirm" "$HEIGHT" "$WIDTH"
clear
#Additional aurmageddon packages
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Installing additional desktop software" \
--prgbox "Installing Aurmageddon packages" "arch-chroot /mnt pacman -S trizen ttf-symbola surfn-icons-git pokemon-colorscripts-git arch-silence-grub-theme-git bibata-cursor-translucent usbimager matcha-gtk-theme nordic-theme nordic-darker-standard-buttons-theme pacman-cleanup-hook ttf-unifont lscolors-git zramswap preload pacman-updatedb-hook needrestart dracula-gtk-theme catppuccin-gtk-theme-mocha redshift-minimal deadbeef --noconfirm" "$HEIGHT" "$WIDTH"
clear


###SETUP CHAOTIC-AUR REPO###
#Add chaotic-aur to pacman.conf. Currently nothing is installed from this
cat << EOF >> /mnt/etc/pacman.conf
#Chaotic-aur repo with many packages
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
#Update pacman repos on the new installation and Arch ISO
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Updating repos" \
--prgbox "Updating pacman repos for chaotic-aur" "arch-chroot /mnt pacman -Syy && pacman -Syy" "$HEIGHT" "$WIDTH"
clear


###CORE SYSTEM SERVICES###
#Enable services
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Enabling Services" \
--prgbox "Enabling core system services" "arch-chroot /mnt systemctl enable NetworkManager systemd-timesyncd ctrl-alt-del.target irqbalance earlyoom zramswap greetd linux-modules-cleanup logrotate.timer fstrim.timer archlinux-keyring-wkd-sync.timer" "$HEIGHT" "$WIDTH"
clear
#Enable performance services if RAM is over ~2GB
ramTotal=$(grep MemTotal /proc/meminfo | grep -Eo '[0-9]*')
if [ "$ramTotal" -gt "2020000" ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Enabling Performance Services" \
	--prgbox "Enabling preload and profile-sync-daemon" "arch-chroot /mnt systemctl enable preload.service && arch-chroot /mnt systemctl --global enable psd.service" "$HEIGHT" "$WIDTH"
fi
clear
#Dbus-broker setup. Disable dbus and then enable dbus-broker for all users
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Enabling Services" \
--prgbox "Enabling dbus-broker" "arch-chroot /mnt systemctl disable dbus.service && arch-chroot /mnt systemctl enable dbus-broker.service && arch-chroot /mnt systemctl --global enable dbus-broker.service" "$HEIGHT" "$WIDTH"
clear


###GPU CHECK/SETUP###
#Determine installed GPU
#By default we install the drivers required for AMD/Intel since those just autoload drivers
#The below installs vulkan drivers and hardware decoding for correct hardware
if lshw -class display | grep "Advanced Micro Devices" || dmesg | grep amdgpu > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found AMD Graphics card" "arch-chroot /mnt pacman -S opencl-mesa vulkan-radeon radeontop --noconfirm" "$HEIGHT" "$WIDTH"
fi
if lshw -class display | grep "Intel Corporation" || dmesg | grep "i915" > /dev/null 2>&1 ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found Intel Graphics card" "arch-chroot /mnt pacman -S vulkan-intel intel-media-sdk libva-intel-driver intel-media-driver intel-gpu-tools --noconfirm" "$HEIGHT" "$WIDTH"
fi
clear


###ADDITIONAL FIRMWARE CHECK/SETUP###
#Detect b43 firmware wifi cards and install b43-firmware
if dmesg | grep -q 'b43-phy0 ERROR'; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found B43 Broadcom Wireless card" "arch-chroot /mnt pacman -S b43-firmware --noconfirm" "$HEIGHT" "$WIDTH"
	clear
fi
#Detect sof audio firmware - https://github.com/thesofproject/sof-bin/
if dmesg | grep -q 'sof-audio'; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detecting hardware" \
	--prgbox "Found missing audio firmware" "arch-chroot /mnt pacman -S sof-firmware sof-tools alsa-utils --noconfirm" "$HEIGHT" "$WIDTH"
	clear
fi


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


###DVD/CD UTILITIES###
#Only install DVD/CD stuff if the device has an optical drive
ls /dev/sr0 > /dev/null 2>&1
if [ $? -eq 0 ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Detected Optical Drive" \
	--prgbox "Installing additional optical drive software" "arch-chroot /mnt pacman -S xfburn udftools libaacs cdrtools dvd+rw-tools --noconfirm" "$HEIGHT" "$WIDTH"
fi
clear


###ZRAM###
#Changes the default amount of zram from 20% to 10% of total system RAM
sed "s,20,10,g" -i /mnt/etc/zramswap.conf


###PULSEAUDIO SETUP###
#Change pulseaudio to have both higher and realtime priority
sed "s,\; high-priority = yes,high-priority = yes,g" -i /mnt/etc/pulse/daemon.conf
sed "s,\; nice-level = -11,nice-level = -11,g" -i /mnt/etc/pulse/daemon.conf
sed "s,\; realtime-scheduling = yes,realtime-scheduling = yes,g" -i /mnt/etc/pulse/daemon.conf
sed "s,\; realtime-priority = 5,realtime-priority = 5,g" -i /mnt/etc/pulse/daemon.conf


###SUDO SETUP###
#Allow wheel users to use sudo
sed "s,\#\ %wheel ALL=(ALL:ALL) ALL,%wheel ALL=(ALL:ALL) ALL,g" -i /mnt/etc/sudoers
cat << EOF >> /mnt/etc/sudoers

###Additional sudo changes###
#Allow additional terminals to run sudo without requiring reauthentication
Defaults timestamp_type=global
#Dont have sudo timeout when running long commands
Defaults passwd_timeout=0
#Show * when typing a password
Defaults env_reset,pwfeedback
#Use nano for the sudo editor
Defaults editor=/usr/bin/rnano
#Allow the user to reboot and poweroff without a password and allow profile-sync-daemon to use overlayfs
$user ALL=(ALL) NOPASSWD:/usr/bin/poweroff,/usr/bin/reboot,/usr/bin/psd-overlay-helper
#Uncomment to allow some commands to be executed without entering the user password
#$user ALL=(ALL) NOPASSWD:/usr/bin/pacman,/usr/bin/trizen,/usr/bin/cpupower,/usr/bin/iotop,/usr/bin/dmesg,/usr/bin/fstrim"
#Log sudo usage
#Defaults log_host, log_year, logfile="/var/log/sudo.log"
#Defaults log_input, log_output
EOF


###MAKEPKG SETUP###
#Setup makepkg config
#Change default job (-j) count to use all cores
sed "s,\#\MAKEFLAGS=\"-j2\",MAKEFLAGS=\"-j\$(nproc)\",g" -i /mnt/etc/makepkg.conf
#Build all packages with native optimizations
sed "s,-mtune=generic,-mtune=native,g" -i /mnt/etc/makepkg.conf
#Enable link time optimizations (LTO)
sed "s,\!lto,lto,g" -i /mnt/etc/makepkg.conf
#Build all rust packages with native optimizations
sed "s,\#\RUSTFLAGS=\"-C opt-level=2\",RUSTFLAGS=\"-C opt-level=2 -C target-cpu=native\",g" -i /mnt/etc/makepkg.conf
#Enable multithreaded and higher level compression support. This only does anything if you change the PKGEXT value
sed "s,COMPRESSGZ=(gzip -c -f -n),COMPRESSGZ=(pigz -c -f -n),g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSBZ2=(bzip2 -c -f),COMPRESSBZ2=(pbzip2 -c -f),g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSXZ=(xz -c -z -),COMPRESSXZ=(xz -e -9 -c -z --threads=0 -),g" -i /mnt/etc/makepkg.conf
sed "s,COMPRESSZST=(zstd -c -z -q -),COMPRESSZST=(zstd -c --ultra -22 --threads=0 -),g" -i /mnt/etc/makepkg.conf
#Change default package extension to just tar (uncompressed)
sed "s,PKGEXT='.pkg.tar.zst',PKGEXT='.pkg.tar',g" -i /mnt/etc/makepkg.conf


###USER CONFIG SETUP - /etc/skel###
#Download config files from github
configFiles=Alexs-Arch-Installer-master
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring system" \
--prgbox "Downloading config files" "wget https://github.com/wailord284/Alexs-Arch-Installer/archive/master.zip && unzip master.zip && rm -r master.zip" "$HEIGHT" "$WIDTH"
#Create /etc/skel dirs for configs to be applied to the new user
mkdir -p /mnt/etc/skel/.config/{gtk-3.0,gtk-2.0,readline,kitty,screen,wezterm,psd,htop,dconf,trizen,nano}
mkdir -p /mnt/etc/skel/.config/systemd/user/psd-resync.timer.d/
mkdir -p /mnt/etc/skel/.local/share/
mkdir -p /mnt/etc/skel/.local/state/
mkdir -p /mnt/etc/skel/.mozilla/
mkdir -p /mnt/etc/skel/.ssh/
#Move nanorc to user and root. Change root users to have a red title bar
mv "$configFiles"/configs/nanorc /mnt/etc/skel/.config/nano/
mkdir -p /mnt/root/.config/nano
cp /mnt/etc/skel/.config/nano/nanorc /mnt/root/.config/nano/
sed "s,set titlecolor bold\,lightwhite,set titlecolor bold\,red\,lightblack,g" -i /mnt/root/.config/nano/nanorc
#Move trizen
mv "$configFiles"/configs/trizen.conf /mnt/etc/skel/.config/trizen/
#Move ssh config to enforce strong clientside ciphers
mv "$configFiles"/configs/ssh-config /mnt/etc/skel/.ssh/config
#Move xsuspender config. We dont enable or install this
mv "$configFiles"/configs/xsuspender.conf /mnt/etc/skel/.config/
#Move profile-sync-daemon config
mv "$configFiles"/configs/psd.conf /mnt/etc/skel/.config/psd/
mv "$configFiles"/configs/systemd/psd-frequency.conf /mnt/etc/skel/.config/systemd/user/psd-resync.timer.d/frequency.conf
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
#Move mimelist. Sets some default apps for file types
mv "$configFiles"/configs/mimeapps.list /mnt/etc/skel/.config/
#Move htoprc
mv "$configFiles"/configs/htoprc /mnt/etc/skel/.config/htop/
#Bash stuff and screenrc. Move to user and root
mv "$configFiles"/configs/bash/inputrc /mnt/etc/skel/.config/readline/
mv "$configFiles"/configs/bash/screenrc /mnt/etc/skel/.config/screen/
mv "$configFiles"/configs/bash/.bashrc /mnt/etc/skel/
mkdir -p /mnt/root/.config/readline
cp /mnt/etc/skel/.config/readline/inputrc /mnt/root/.config/readline/
cp /mnt/etc/skel/.bashrc /mnt/root/.bashrc
#Move Firefox config and set permissions for extra privacy
mv "$configFiles"/configs/firefox/ /mnt/etc/skel/.mozilla/
chmod -R 700 /mnt/etc/skel/.mozilla/firefox/
#Make gnupg config folder. Required with custom XDG
mkdir -p /mnt/etc/skel/.local/share/gnupg/
chmod -R 700 /mnt/etc/skel/.local/share/gnupg


###USER, PASSWORDS and PAM###
#Add user here to get /etc/skel configs
arch-chroot /mnt useradd -m -G network,kvm,floppy,disk,storage,uucp,wheel,optical -s /bin/bash "$user"
#Create a temp file to store the password in
TMPFILE=$(mktemp)
#Create normal user account password
echo "$user":"$pass" > "$TMPFILE"
arch-chroot /mnt chpasswd < "$TMPFILE"
#Set the root password
echo "root":"$pass" > "$TMPFILE"
arch-chroot /mnt chpasswd < "$TMPFILE"
#Unset and delete the passwords stored in pass1 pass2 pass and encpass encpass1 encpass2
unset pass1 pass2 pass encpass encpass1 encpass2
rm -rf "$TMPFILE"
#Setup stronger password security by increasing delay between password attempts to 4 seconds
echo "auth optional pam_faildelay.so delay=5000000" >> /mnt/etc/pam.d/system-login
#Require users to be in the wheel group to run su
echo "auth required pam_wheel.so use_uid" >> /mnt/etc/pam.d/su
echo "auth required pam_wheel.so use_uid" >> /mnt/etc/pam.d/su-l
#Remove annoying systemd-homed log messages anytime sudo is used. Normally seen in journalctl
sed '/systemd_home/d' -i /mnt/etc/pam.d/system-auth


###FONTS###
#Set fonts
arch-chroot /mnt ln -s /usr/share/fontconfig/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /usr/share/fontconfig/conf.avail/10-hinting-full.conf /etc/fonts/conf.d


###ENVIRONMENT VARIABLES###
#These variables help enforce config files out of the home directory
mv "$configFiles"/configs/xdg.sh /mnt/etc/profile.d/


###NETWORKMANAGER###
mkdir -p /mnt/etc/NetworkManager/conf.d/
#Configure mac address spoofing on startup via NetworkManager. Only wireless interfaces are randomized
mv "$configFiles"/configs/networkmanager/rand_mac.conf /mnt/etc/NetworkManager/conf.d/
#Set default DNS to cloudflare
mv "$configFiles"/configs/networkmanager/dns-servers.conf /mnt/etc/NetworkManager/conf.d/
#Set NetworkManager to avoid systemd-resolved. Fixes issue "unit dbus-org.freedesktop.resolve1.service not found" in journal log
mv "$configFiles"/configs/networkmanager/no-systemd-resolve.conf /mnt/etc/NetworkManager/conf.d/
#Enable IPv6 privacy
mv "$configFiles"/configs/networkmanager/ip6-privacy.conf /mnt/etc/NetworkManager/conf.d/


###UDEV RULES###
#IOschedulers for storage that "should" increase perfomance
mv "$configFiles"/configs/udev/60-ioschedulers.rules /mnt/etc/udev/rules.d/
#HDParm rule to spin down drives after 20 idle minutes. Increases access times after idle periods but increases HDD life
mv "$configFiles"/configs/udev/69-hdparm.rules /mnt/etc/udev/rules.d/


###POLKIT RULES###
#The following rules allow the user to not enter a password if in the correct group for specific applications.
#Add libvirt rule for the kvm group (you don't need to be in the libvirt group now)
mv -f "$configFiles"/configs/polkit-1/50-libvirt.rules /mnt/etc/polkit-1/rules.d/
#Add gparted polkit rule for the disk group
mv -f "$configFiles"/configs/polkit-1/00-gparted.rules /mnt/etc/polkit-1/rules.d/
#Add gsmartcontrol rule for the disk group
mv -f "$configFiles"/configs/polkit-1/50-gsmartcontrol.rules /mnt/etc/polkit-1/rules.d/
#Allow users in the network group to add/modify/delete networks
mv -f "$configFiles"/configs/polkit-1/50-networkmanager.rules /mnt/etc/polkit-1/rules.d/


###SCRIPTS###
#Custom scripts
mkdir -p /mnt/opt/scripts/
mv "$configFiles"/configs/scripts/* /mnt/opt/scripts/


###PACMAN HOOKS###
#Add the needrestart and grub reinstall pacman hook
mkdir -p /mnt/etc/pacman.d/hooks/
mv "$configFiles"/configs/pacman-hooks/needrestart.hook /mnt/etc/pacman.d/hooks/
mv "$configFiles"/configs/pacman-hooks/update-grub.hook /mnt/etc/pacman.d/hooks/
mv "$configFiles"/configs/pacman-hooks/clean-pacman-cache.hook /mnt/etc/pacman.d/hooks/


###WACOM TABLET###
#Check and setup touchscreen for devices like the Thinkpad X201T/X220T
if grep -i wacom /proc/bus/input/devices > /dev/null 2>&1 ; then
	mv "$configFiles"/configs/xorg/72-wacom-options.conf /mnt/etc/X11/xorg.conf.d/
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Touchscreen Found" \
	--prgbox "Install Touchscreen driver" "arch-chroot /mnt pacman -S xf86-input-wacom --noconfirm" "$HEIGHT" "$WIDTH"
	clear
fi


###LAPTOP SETUP###
#Setup laptop features if detected
if acpi -V | grep -iq Battery ; then acpiBattery=yes; fi
if [ -d "/sys/class/power_supply/BAT0" ] || [ -d "/sys/class/power_supply/BAT1" ]; then sysBattery=yes; fi
chassisType=$(hostnamectl | grep "Chassis" | cut -d":" -f2 | cut -d" " -f2)
if [ "$chassisType" = laptop ] || [ "$chassisType" = tablet ] || [ "$acpiBattery" = yes ] || [ "$sysBattery" = yes ]; then
	#Move the powertop auto tune service so it can be enabled if the user wants. TLP does the same thing. Disable by default
	mv "$configFiles"/configs/systemd/powertop.service /mnt/etc/systemd/system/
	#Install power saving tools and enable tlp
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Laptop Found" \
	--prgbox "Setting up powersaving features" "arch-chroot /mnt pacman -S ethtool powertop x86_energy_perf_policy xf86-input-synaptics iio-sensor-proxy tlp tlp-rdw --noconfirm && arch-chroot /mnt systemctl enable tlp.service" "$HEIGHT" "$WIDTH"
	#Add touchpad config
	mv "$configFiles"/configs/xorg/70-synaptics.conf /mnt/etc/X11/xorg.conf.d/
	#Laptop mode
	mv "$configFiles"/configs/sysctl/00-laptop-mode.conf /mnt/etc/sysctl.d/
	#Set PCIE powersave in TLP. Can make a significant improvement on some newer laptops
	sed "s,\#\PCIE_ASPM_ON_BAT=default,PCIE_ASPM_ON_BAT=powersupersave,g" -i /mnt/etc/tlp.conf
	#Mask rfkill for TLP
	arch-chroot /mnt systemctl mask systemd-rfkill.socket systemd-rfkill.service > /dev/null 2>&1
	#Increase dirty writeback time to 60 seconds. Same as TLP but always enforced
	mv "$configFiles"/configs/sysctl/50-dirty-writebacks.conf /mnt/etc/sysctl.d/
	#Disable wake on lan. May help with power savings
	mv "$configFiles"/configs/udev/81-disable_wol.rules /mnt/etc/udev/rules.d/
	mv "$configFiles"/configs/networkmanager/wake-on-lan.conf /mnt/etc/NetworkManager/conf.d/
	#Enable wifi powersaving
	mv "$configFiles"/configs/udev/81-wifi-powersave.rules /mnt/etc/udev/rules.d/
	clear
fi


###FILESYSTEM - BTRFS###
#lAdd some extra software and configs when using BTRFS
if [ "$filesystem" = btrfs ] ; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "Installing Additional Software and Regenerating initramfs for BTRFS" \
	--prgbox "Adding configs and software for BTRFS. This may take a while..." "arch-chroot /mnt pacman -S snapper snap-pac btrfs-assistant --noconfirm" "$HEIGHT" "$WIDTH"
	#Make locate not index .snapshots directory
	sed "s,PRUNENAMES = \".git .hg .svn\",PRUNENAMES = \".git .hg .svn .snapshots\",g" -i /mnt/etc/updatedb.conf
	#Add the btrfs binary to mkinitcpio for recovery situations
	sed "s,BINARIES=(),BINARIES=(btrfs),g" -i /mnt/etc/mkinitcpio.conf
	#Change the snapper-cleanup timer run every six hours instead of once per day
	mkdir -p /mnt/etc/systemd/system/snapper-cleanup.timer.d/
	mv "$configFiles"/configs/systemd/00-snapper-cleanup-time.conf /mnt/etc/systemd/system/snapper-cleanup.timer.d/
	#Add the fristboot systemd script for snapper and enable the monthly btrfs scrub timer
	mv "$configFiles"/configs/systemd/snapper-firstboot.service /mnt/etc/systemd/system/
	arch-chroot /mnt systemctl enable snapper-firstboot.service btrfs-scrub@-.timer > /dev/null 2>&1
	#Add btrfs assistant rule for storage group. Allows users to open btrfsassistant without a password
	mv -f "$configFiles"/configs/polkit-1/50-btrfsassistant.rules /mnt/etc/polkit-1/rules.d/
	#Skip FSCK for btrfs since it is not needed. Also remove the fsck mkinitcpio hook
	grubCmdlineLinuxOptions="fsck.mode=skip"
	#Mask the fsck service as well just in cace
	arch-chroot /mnt systemctl mask systemd-fsck-root.service
	grep HOOKS= /mnt/etc/mkinitcpio.conf | tail -n1 | sed -e "s/ fsck//g" -i /mnt/etc/mkinitcpio.conf
	arch-chroot /mnt mkinitcpio -P > /dev/null 2>&1
	clear
fi


###MODULES###
#Load the tcp_bbr module for better networking. This is utilized in the network sysctl config (30-network.conf)
echo 'tcp_bbr' > /mnt/etc/modules-load.d/tcp_bbr.conf


###GREETD - DISPLAY MANAGER###
sed 's,command = "agreety --cmd /bin/sh",command = "tuigreet -t -r -i --asterisks --cmd startxfce4",g' -i /mnt/etc/greetd/config.toml
#Make sure needrestart does not restart greetd. This has been fixed but has not yet been released: https://github.com/liske/needrestart/commit/301729b2d8d4ac90ded4f7cd3797da114bc295ac
sed 's,xdm,greetd,g' -i /mnt/etc/needrestart/needrestart.conf


###SYSTEMD###
#Set journal to output log contents to TTY12
mkdir /mnt/etc/systemd/journald.conf.d
mv "$configFiles"/configs/systemd/fw-tty12.conf /mnt/etc/systemd/journald.conf.d/
#Set a lower systemd service timeout
mkdir /mnt/etc/systemd/system.conf.d/
mv "$configFiles"/configs/systemd/00-service-timeout.conf /mnt/etc/systemd/system.conf.d/
#Set journal to only keep 1024MB of logs
mv "$configFiles"/configs/systemd/00-journal-size.conf /mnt/etc/systemd/journald.conf.d/
#Disable systemd coredumps
mkdir /mnt/etc/systemd/coredump.conf.d/
mv "$configFiles"/configs/systemd/00-disable-coredumps.conf /mnt/etc/systemd/coredump.conf.d/
#Add the TTY Interfaces service to output interface IP addresses to the TTY login screen. Not enabled
mv "$configFiles"/configs/systemd/ttyinterfaces.service /mnt/etc/systemd/system/
#Lower the logs from rtkit. Reduces the spam in journalctl
mkdir -p /mnt/etc/systemd/system/rtkit-daemon.service.d
mv "$configFiles"/configs/systemd/00-rtkit-loglevel.conf /mnt/etc/systemd/system/rtkit-daemon.service.d/


###REFLECTOR###
#Configure reflector to save the 10 fastest mirrors
cat << EOF > /mnt/etc/xdg/reflector/reflector.conf
#Save location
--save /etc/pacman.d/mirrorlist
#Save the 10 fastest mirrors
-f 10
#Mirrorlist protocol
--protocol https
#Mirrorlist country
--country $region
#Most recent mirrors to check
--latest 20 --age 24
#Sort mirrors by download speed
--sort rate
#Give up after 10 seconds if a mirror does not reply
--download-timeout 10 --connection-timeout 10
EOF
#Enable the weekly reflector timer
arch-chroot /mnt systemctl enable reflector.timer > /dev/null 2>&1


###SYSCTL RULES###
#Allow unprivileged_userns_clone for programs like Zoom. Disabled bu default
mv "$configFiles"/configs/sysctl/00-unprivileged-userns.conf /mnt/etc/sysctl.d/
#Low-level console messages
mv "$configFiles"/configs/sysctl/10-console-messages.conf /mnt/etc/sysctl.d/
#Kernel hardening
mv "$configFiles"/configs/sysctl/10-kernel-hardening.conf /mnt/etc/sysctl.d/
#System tweaks
mv "$configFiles"/configs/sysctl/30-system-tweak.conf /mnt/etc/sysctl.d/
#Network tweaks
mv "$configFiles"/configs/sysctl/30-network.conf /mnt/etc/sysctl.d/
#RAM and storage tweaks
mv "$configFiles"/configs/sysctl/50-dirty-bytes.conf /mnt/etc/sysctl.d/


###GRUB INSTALL###
#Grub install
if [ "$boot" = efi ]; then
	if [ "$bootArch" = 64 ]; then
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "GRUB installation" \
		--prgbox "Installing grub for UEFI" "arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable --recheck" "$HEIGHT" "$WIDTH"
	else
		dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "GRUB installation" \
		--prgbox "Installing grub for 32-bit UEFI" "arch-chroot /mnt grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=GRUB --removable --recheck" "$HEIGHT" "$WIDTH"
	fi
	#Install memtest86 for UEFI
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Memtest86" \
		--prgbox "Installing memtest86 for UEFI" "arch-chroot /mnt pacman -S memtest86+-efi --noconfirm" "$HEIGHT" "$WIDTH"
fi
if [ "$boot" = bios ]; then
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
	--title "GRUB installation" \
	--prgbox "Installing grub for legacy BIOS" "arch-chroot /mnt grub-install --target=i386-pc $storage --recheck" "$HEIGHT" "$WIDTH"
	#Install memtest86 for BIOS
	dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
		--title "Memtest86" \
		--prgbox "Installing memtest86 for legacy BIOS" "arch-chroot /mnt pacman -S memtest86+ --noconfirm" "$HEIGHT" "$WIDTH"
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


###GRUB AND PERFORMANCE BOOT OPTIONS###
#Check the output of cat /sys/power/mem_sleep for the systems sleep mode
#If the system is using s2idle but also has deep sleep mode availible, switch it to deep
#This is especially needed on the 11th gen Framework laptop, although others may benefit
#This setting does make the laptop take longer to wake from sleep, but reduces power consumption a decent bit
sleepMode=$(cat /sys/power/mem_sleep)
if [ "$sleepMode" = "[s2idle] deep" ]; then
	#If the system has both s2idle and deep but s2idle is currently selected, then deep sleep will be used
	#This will set mem_sleep_default=deep in grub - GRUB_CMDLINE_LINUX
	grubCmdlineLinuxOptions="mem_sleep_default=deep $grubCmdlineLinuxOptions"
fi
#If mitigations are wanted, add them as well as grubCmdlineLinuxOptions. If deep sleep was selected it will be added
#Also make sure to blacklist some watchdog modules which may keep watchdog loaded
if [ "$enableGrubPerformanceOptions" = "y" ]; then
	grubCmdlineLinuxOptions="$grubPerformanceOptions $grubCmdlineLinuxOptions"
	mv "$configFiles"/configs/disable-watchdog.conf /mnt/etc/modprobe.d/
	mv "$configFiles"/configs/sysctl/10-disable-watchdog.conf /mnt/etc/sysctl.d/
fi


###GRUB CONFIG###
#Generate grubcfg with root UUID if encrypt=y
if [ "$encrypt" = y ]; then
	rootTargetDiskUUID=$(blkid -s UUID -o value ${storagePartitions[2]})
	#Check if the device is an SSD. If it is, enable discard - https://wiki.archlinux.org/title/Dm-crypt/Specialties#Discard/TRIM_support_for_solid_state_drives_(SSD)
	if [ "$deviceUsesSSD" = yes ]; then
		sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$rootTargetDiskUUID:cryptroot:allow-discards root=$rootTargetDisk audit=0 loglevel=3\",g" -i /mnt/etc/default/grub
	else
		sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$rootTargetDiskUUID:cryptroot root=$rootTargetDisk audit=0 loglevel=3\",g" -i /mnt/etc/default/grub
	fi
else
	#Generate grubcfg if no encryption
	sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"audit=0 loglevel=3\",g" -i /mnt/etc/default/grub
fi
#Append additional grub boot options if selected
if [ -z "$grubCmdlineLinuxOptions" ]; then
	true #Do nothing if unset
else
	sed "s,\GRUB_CMDLINE_LINUX=\"\",\GRUB_CMDLINE_LINUX=\"$grubCmdlineLinuxOptions\",g" -i /mnt/etc/default/grub
fi
#Change theme
echo 'GRUB_THEME="/boot/grub/themes/arch-silence/theme.txt"' >> /mnt/etc/default/grub
#Change timeout to 3 seconds from 5 seconds. Set to 1 if performance options are set
if [ "$enableGrubPerformanceOptions" = "y" ]; then
	sed 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g' -i /mnt/etc/default/grub
else
	sed 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/g' -i /mnt/etc/default/grub
fi
#Generate grubcfg
dialog --scrollbar --timeout 1 --backtitle "$dialogBacktitle" \
--title "Configuring grub" \
--prgbox "Generating grubcfg" "arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg" "$HEIGHT" "$WIDTH"
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
echo "$green""6$reset - Enable automatic desktop login $green(recommended)"
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
		bedrockVersion="0.7.29"
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
		echo "$green""Enabling sshd""$reset"
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

		6) #Desktop login - greetd
		echo "$green""Enabling automatic desktop login""$reset"
		echo -e '\n' >> /mnt/etc/greetd/config.toml
		echo "[initial_session]" >> /mnt/etc/greetd/config.toml
		echo "command = startxfce4" >> /mnt/etc/greetd/config.toml
		echo "user = $user" >> /mnt/etc/greetd/config.toml
		sleep 3s
		;;

		7) #hblock
		#run hblock to prevent ads
		echo "$green""Running hblock and enabling weekly hblock timer. The system host file will be modified""$reset"
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
		#Enable service
		arch-chroot /mnt systemctl enable doh-client.service
		sleep 3s
		;;

		q) #Finish
		#Unmount the drive and finish
		if [ "$encrypt" = y ]; then
			cryptsetup close cryptroot
		fi
		umount -R /mnt
		umount -R /mnt/boot
		clear
		echo -e "$green""Installation Complete. All drives have been unmounted and you can now reboot.\nThanks for installing!""$reset"
		sleep 3s
		exit 0
		;;
	esac
done
