#!/bin/bash
#Automated Arch Linux installation script by Alex "wailord284" Gaudino.
###HOW TO USE###
#To use this, burn the Arch Linux ISO to a usb drive and boot it. Once botted download this file.
#If you're on wifi, run wifi-menu first to connect to the internet or put this script on a second drive to be prompted.
#1) wget wailord284.club/repo/install.sh 2) chmod +x install.sh 3) ./install.sh
#This script can operate in two different modes.
##Mode 1: Interactive. Running the script (./install.sh) with no arguments will prompt the user for required values.
##Mode 2: Traditional. Running the script with flag options. Run ./install --help to get a list of options
###Example command: ./install.sh -c America -ci Los_Angeles -h Arch -p password -s /dev/sda -u wailord284 -w n
###ABOUT###
#This script will autodetect a large range of hardware and should automatically configure many systems out of the box.
##UEFI and Legacy BIOS are supported. Currently NVidia is not 100% supported but at the end users can manually install the driver.
##At this time, disk encryption only works on UEFI but will soon be implemented for all systems.
#This script will install Arch with mainly vanilla settings plus some programs and features I personally use.
#To install applications I like, I've created a custom software repository known as "Aurmageddon"
##Aurmageddon has 1500+ packages that recieve updates every 6 hours. Some software used in this install comes from this repo.
##To view this repo, go to http://wailord284.club/repo/aurmageddon/x86_64/
##This repo is unsigned but personally maintained by me. Package requests go to wailord284 on gmail.
#Please be aware that some of the changes this script will make are focused on settings I enjoy.
#All the post install options are optional but may improve your experience. Some options are selected by default.
#This is an ongoing project of mine and will recieve constant updates and improvements.
#Eventually most if not all the echo commands will be moved to config files on Github. But it works fine for now.

###Things to maybe add###
#add permrs https://github.com/gort818/permrs - make systemd timer https://www.putorius.net/using-systemd-timers.html
#add option for fail2ban
#tzupdate to replace networkmanager curl timezone thing
#https://donatoroque.wordpress.com/2017/08/13/setting-up-rkhunter-using-systemd/ - rkhunter script
#https://wiki.archlinux.org/index.php/Readline#Faster_completion
#XFCE4 panel, items, window buttons, item grouping -> never
#https://wiki.archlinux.org/index.php/Getty#Automatic_login_to_virtual_console
#add support for /dev/md0
#irqbalance
#https://wiki.archlinux.org/index.php/Network_configuration#Promiscuous_mode

#colors
#white=$(tput setaf 7)
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
red=$(tput setaf 1)
reset=$(tput sgr 0)
#Create options for the install script
#https://likegeeks.com/linux-bash-scripting-awesome-guide-part3/
while [ -n "$1" ]; do

	case "$1" in

	-c)
		optionCountry="$2"
		shift ;;

	-ci)
		optionCity="$2"
		shift ;;

	-e) 
		optionEncrypt="$2"
		shift ;;

	-h)
		optionHostname="$2"
		shift ;;

	-p)
		optionPassword="$2"
		shift ;;

	-s)
		optionStorage="$2"
		shift ;;

	-u)
		optionUser="$2"
		shift ;;

	-w)
		optionWipe="$2"
		shift ;;

	--help)
		echo "Defaults are used during the automated install. If a required option for installation is not specified, you will be prompted."
		echo -e "List of all availible options:\n"
		echo "-c	Set the country for the system timezone. A list can be found in /usr/share/zoneinfo. Default = America"
		echo "-ci	Set the city for the system timezone. A list can be found in /usr/share/zoneinfo/country. Default = Phoenix"
		echo "-e	Encrypt the main partition. Must be y or n for (y)es or (n)o. Default = n"
		echo "-h	Set the hostname for the system. Default = archlinux"
		echo "-p	Set the password for the root and default user account. Default = pass"
		echo "-s	Specify the storage device to install to. Must be in the format of /dev/sda, /dev/nvme0n1 or /dev/mmcblk0"
		echo "-u	Set the user for the default account. Do not use any caps. Default = alex"
		echo "-w	Securely erase the drive before install using random data and shred. Must be y or n for (y)es or (n)o. Default = n"
		echo "--help	Show this menu!"
		exit 0
		shift ;;

	*) echo "Option $1 not recognized" && exit 1 ;;
		esac
		shift
done


#configure internet
clear && echo "$green""Welcome to Alex's automatic install script!""$reset"
echo "$green"'Checking internet connection...'"$reset"
if wget -q --spider http://google.com ; then
	echo "$green""Online""$reset"
else
	echo "$red""Offline - connecting to wifi""$reset"
	sleep 1s
	wifi-menu
fi
#Set time
timedatectl set-ntp true

#user inputs
#Set the hostname
if [ -z "$optionHostname" ]; then
	echo "$green""Enter hostname - default archlinux""$reset"
	read -r -p "Hostname: " host
	#set host to archlinux if user just presses enter
	host=${host:-archlinux}
	clear
else
	echo "$yellow""Hostname manually specified with value $optionHostname""$reset"
	host="$optionHostname"
fi

#Timezone - country
if [ -z "$optionCountry" ]; then
	echo "$green""Pick a country - default America""$reset"
	ls /usr/share/zoneinfo
	read -r -p "Country: " country
	country=${country:-America} #Default to America
else
	echo "$yellow""Country manually specified with value $optionCountry""$reset"
	country="$optionCountry" #Skip country setup if optionCountry is set
fi
#Timezone - city
if [ -z "$optionCity" ]; then
	if [ -d /usr/share/zoneinfo/"$country" ]; then #Check to see if the country has additional timezones
		echo "$green""Pick a city - default Los Angeles""$reset"
		ls /usr/share/zoneinfo/"$country"/
		read -r -p "City: " city
		#city=${city:-Phoenix}
		city=${city:-Los_Angeles} #Default to Los_Angeles
	else
		echo "$yellow""Country does not have any other timezones""$reset"
	fi
else
	echo "$yellow""City manually specified with value $optionCity""$reset"
	city="$optionCity" #Skip city setup if optionCity is set
fi
clear && echo "$green""Timezone set as $country $city""$reset" && clear

#desktop
desktop=${desktop:-xfce}

#username
if [ -z "$optionUser" ]; then
	echo "$green""Enter username - no caps - default alex""$reset"
	read -r -p "Username: " user
	user=${user:-alex}
	clear
else
	echo "$yellow""User manually specified with value $optionUser""$reset"
	user="$optionUser"
fi

#verify password match
if [ -z "$optionPassword" ]; then
	while : ;do
		echo "$green""Enter password for default and root user - hidden - default pass""$reset"
		read -r -s -p "Pass1: " pass1
		pass1=${pass1:-pass}
		clear
		echo "$green""Enter password again - hidden - default pass""$reset"
		read -r -s -p "Pass2: " pass2
		pass2=${pass2:-pass}
		clear
		if [ "$pass1" = "$pass2" ]; then
			echo "$green""Passwords match - continuing""$reset"
			pass="$pass1"
			break #exit loop
		else
			echo "$red""Passwords do not match - please try again""$reset"
		fi
	done
else
	echo "$yellow""Password manually specified with value $optionPassword""$reset"
	pass="$optionPassword"
fi

#Encryption/security - only availible on UEFI cause idk how it works on old BIOS (wont boot grub - maybe its encrypted?)
if [ -z "$optionEncrypt" ]; then
	echo "$green""Do you want to enable LUKS encryption? y/n - default (n)o""$reset"
	read -r -p "Encryption: " encrypt
	encrypt=${encrypt:-n}
	clear
elif [ "$optionEncrypt" = y ]; then
	echo "$yellow""Encryption manually set to yes""$reset"
	encrypt=${encrypt:-y}
	boot=$(ls /sys/firmware | grep efi)
	if [ "$boot" != efi ]; then
		#Broken - doesnt set encrypt to n correctly for some reason?
		encrypt="n"
		echo "$red""You're running on a non UEFI device. Disabling encryption.""$reset"
	fi
elif [ "$optionEncrypt" = n ]; then
	echo "$yellow""Encryption manually set to no""$reset"
fi

#If encrypt is yes, ask for encryption password
##The goal of this was to input the users encryption password into cryptsetup 3 times so the user didnt have to
##cryptsetup wont accept input for some reason and tends to set the password to the name of the variable
#if [ "$encrypt" = y ]; then
#	while : ;do #run infinite loop until encpass1 = encpass2
#		echo "$green""You said yes to encryption. Please enter a password to use for the drive - hidden - default P4ssw0rd""$reset"
#		read -r -s -p "Encryption Pass1: " encpass1
#		pass1=${pass1:-P4ssw0rd}
#		clear
#		echo "$green""Enter password again - hidden - default P4ssw0rd""$reset"
#		read -r -s -p "Encryption Pass2: " encpass2
#		pass2=${pass2:-P4ssw0rd}
#		clear
#		if [ "$encpass1" = "$encpass2" ]; then
#			echo "$green""Passwords match - continuing""$reset"
#			encpass="$encpass1"
#			#store pass into file
#			ENCTEMP=$(mktemp) || exit 1
#			trap 'rm -f "$ENCTEMP"' EXIT
#			echo "$encpass" > "$ENCTEMP"
#			echo "$encpass" > enc.txt
#			break #exit loop
#		else
#			echo "$red""Passwords do not match - please try again""$reset"
#		fi
#	done
#fi

#Setup storage device for install
declare -a storagePartitions
while : ; do
	#Choose disk to install to - $storage. Only run if storage device was not set with -s ($optionStorage)
	if [ -z "$optionStorage" ]; then
		parted -l
		echo -e "$green""Enter the disk you want to install Arch on.$reset$yellow\nThis will erase the entire drive and all its data.\nDual booting or manual partitioning is NOT available at this time.""$reset"
		read -r -p "Drive: " storage
	else
		echo "$yellow""Storage device manually specified with value $optionStorage""$reset"
		storage="$optionStorage"
	fi
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
		echo "$red""Invalid storage device enetered. Must be in the format of /dev/sda, /dev/nvme0n1, /dev/mmcblk0.""$reset"
		sleep 10s
	fi
done

#Optionally erase the drive using shred
if [ "$optionWipe" = n ]; then
	echo "$yellow""Secure Drive wipe manually set to no""$reset"
	wipe="n"
elif [ "$optionWipe" = y ]; then
	#Wipe drive if the user said yes
	echo "$yellow""Secure Drive wipe manually set to yes""$reset"
	wipe="y"
elif [ -z "$optionWipe" ]; then
	echo -e "$green""\nDo you want to securely erase the drive by overwriting it with random data? y/n - default (n)o""$reset"
	echo "$yellow""Please note that depending on the size and speed of the drive, this can take a LONG time""$reset"
	read -r -p "Wipe: " wipe
	wipe=${wipe:-n}
fi


#Show the user the final install settings and prompt to continue
clear
echo "$green""Installing with the following options:""$reset"
echo "$green""Hostname: $reset$host"
echo "$green""Timezone: $reset$country,$city"
echo "$green""Username: $reset$user""$reset"
echo "$green""Disk Encryption: $reset$encrypt"
echo "$green""Install Drive: $reset$storage"
echo "$green""Secure Drive Wipe: $reset$wipe"
echo -e "$red""\n!!!WARNING!!! This will delete ALL DATA on the drive.\nAre you sure you want to continue? y/n""$reset"
read -r -p "Continue Installation?: " finalInstall
finalInstall=${finalInstall:-n}
#Exit script is user enters n
if [ "$finalInstall" = n ]; then
	echo "$green""Installation canceled""$reset"
	exit 0
else
	echo "$green""Starting installation on $storage with partitions ${storagePartitions[*]}""$reset"
	echo "$red""Installing to $storage in 10 seconds...""$reset" && sleep 10s
fi


#Before starting, wipe the drive if user said y to wipe
if [ "$wipe" = y ]; then
	echo "$red""Overwriting all data. This may take a while...""$reset"
	shred --verbose --random-source=/dev/urandom -n1 "$storage"
fi


#Start the install
#detect efi/uefi bios
#https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system
#https://forums.gentoo.org/viewtopic-p-5254317.html
boot=$(ls /sys/firmware | grep efi) #switch to grep efi /sys/firmware/
if [[ "$boot" = efi && "$encrypt" = y ]]; then
	echo "$green""UEFI boot with encryption""$reset"
	#wipe drive - "${storagePartitions[1]}" is boot partition
	wipefs --all "$storage"
	yes | mkfs.ext4 "$storage"
	#create fat32 efi partition
	parted -s "$storage" mklabel gpt
	parted -s "$storage" mkpart primary fat32 1MiB 260MiB
	parted -s "$storage" set 1 esp on
	#create ext4 root partition
	parted -s "$storage" mkpart primary ext4 260MiB 100%
	#Format partitions
	cryptsetup -v -y --iter-time 3000 --type luks2 --key-size 512 --hash sha512 luksFormat "${storagePartitions[2]}"
	cryptsetup open "${storagePartitions[2]}" cryptroot
	mkfs.ext4 /dev/mapper/cryptroot
	mount /dev/mapper/cryptroot /mnt
	#Mount and partition boot drive
	mkfs.vfat -F32 "${storagePartitions[1]}"
	mkdir /mnt/boot
	mount "${storagePartitions[1]}" /mnt/boot
fi
if [[ "$boot" = efi && "$encrypt" = n ]]; then
	echo "$green""UEFI boot no encryption""$reset"
	#wipe drive - "${storagePartitions[1]}" is boot partition
	wipefs --all "$storage"
	yes | mkfs.ext4 "$storage"
	#create fat32 efi partition
	parted -s "$storage" mklabel gpt
	parted -s "$storage" mkpart primary fat32 1MiB 260MiB #551MiB
	parted -s "$storage" set 1 esp on
	#create ext4 root partition
	parted -s "$storage" mkpart primary ext4 260MiB 100% #551MiB
	#Format partitions
	mkfs.vfat -F32 "${storagePartitions[1]}"
	mkfs.ext4 "${storagePartitions[2]}"
	#Mount drive
	mount "${storagePartitions[2]}" /mnt
	mkdir /mnt/boot
	mount "${storagePartitions[1]}" /mnt/boot
fi
#legacy
if [[ -z "$boot" && "$encrypt" = y ]]; then
	echo "$green""Legacy BIOS with encryption""$reset"
	#wipe drive - "${storagePartitions[1]}" is boot partition
	wipefs --all "$storage"
	yes | mkfs.ext4 "$storage"
	#create ext4 boot partition
	parted -s "$storage" mklabel msdos #BIOS needs msdos
	parted -s "$storage" mkpart primary ext4 1MiB 260MiB #bios requires ext4
	parted -s "$storage" set 1 boot on #mark bootable
	#create ext4 root partition
	parted -s "$storage" mkpart primary ext4 260MiB 100%
	#Format partitions
	cryptsetup -v -y --iter-time 3000 --type luks2 --key-size 512 --hash sha512 luksFormat "${storagePartitions[2]}"
	cryptsetup open "${storagePartitions[2]}" cryptroot
	mkfs.ext4 /dev/mapper/cryptroot
	mount /dev/mapper/cryptroot /mnt
	#Mount and partition boot drive
	mkfs.ext4 "${storagePartitions[1]}"
	mkdir /mnt/boot
	mount "${storagePartitions[1]}" /mnt/boot
fi
if [[ -z "$boot" && "$encrypt" = n ]]; then
	echo "$green""Legacy BIOS without encryption""$reset"
	#wipe drive - "${storagePartitions[1]}" is main partition
	wipefs --all "$storage"
	yes | mkfs.ext4 "$storage"
	parted -s "$storage" mklabel msdos
	parted -s "$storage" mkpart primary ext4 1MiB 100%
	parted -s "$storage" set 1 boot on
	mkfs.ext4 "${storagePartitions[1]}"
	mount "${storagePartitions[1]}" /mnt
fi


#Install system, grub, mirrors
clear && echo "$green""Please wait while the fastest mirrors are selected...""$reset"
pacman -Syy
pacman -S reflector --noconfirm
reflector --latest 200 --country US --protocol http --protocol https --age 12 --sort rate --save /etc/pacman.d/mirrorlist
#Remove the following mirrors. For some reason they behave randomly 
sed '/mirror.lty.me/d' -i /etc/pacman.d/mirrorlist
sed '/mirrors.kernel.org/d' -i /etc/pacman.d/mirrorlist


clear && echo "$green""Installing the base system""$reset" && sleep 1s
pacstrap /mnt base base-devel --noconfirm
#Enable some options in pacman.conf
sed "s,\#\VerbosePkgLists,VerbosePkgLists,g" -i /mnt/etc/pacman.conf
sed "s,\#\TotalDownload,TotalDownload,g" -i /mnt/etc/pacman.conf
sed "s,\#\Color,Color,g" -i /mnt/etc/pacman.conf


clear && echo "$green""Installing additional base software...""$reset" && sleep 1s
#install kernel here as new base pkg removes linux
arch-chroot /mnt pacman -S linux linux-headers linux-firmware mkinitcpio grub efibootmgr dosfstools mtools os-prober crda --noconfirm
#Install amd or intel ucode based on cpu
vendor=$(cat /proc/cpuinfo | grep -m 1 "vendor" | grep -o "Intel")
if [ "$vendor" = Intel ]; then
	echo "$blue""Intel CPU found. Installing intel-ucode""$reset"
	arch-chroot /mnt pacman -S intel-ucode --noconfirm
else
	echo "$red""AMD CPU found. Installing amd-ucode""$reset"
	arch-chroot /mnt pacman -S amd-ucode --noconfirm
fi
clear && echo "$green""Base installed - generating core configs""$reset"


#Enable encryption mkinitcpio hooks if needed and set lz best compression
if [ "$encrypt" = y ]; then
	sed "s,HOOKS=(base udev autodetect modconf block filesystems keyboard fsck),HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck),g" -i /mnt/etc/mkinitcpio.conf
	echo "$green""Added encypt hook to mkinitcpio""$reset"
fi
sed "s,\#\COMPRESSION=\"lz4\",COMPRESSION=\"lz4\",g" -i /mnt/etc/mkinitcpio.conf
#sed "s,\#\COMPRESSION_OPTIONS=(),COMPRESSION_OPTIONS=(-9),g" -i /mnt/etc/mkinitcpio.conf


#Create FSTAB and use inputs
genfstab -U /mnt >> /mnt/etc/fstab
#Set timezone
if [ -z "$city" ]; then
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$country" /etc/localtime
else
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$country"/"$city" /etc/localtime
fi
arch-chroot /mnt hwclock --systohc
#set locale
sed "s,\#\en_US.UTF-8 UTF-8,en_US.UTF-8 UTF-8,g" -i /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
#Set language
echo 'LANG=en_US.UTF-8' >> /mnt/etc/locale.conf
#set hostname
echo "$host" >> /mnt/etc/hostname
clear && echo "$green""Locale, timezone and fstab set - setting password""$reset"


#create and add user/password
arch-chroot /mnt groupadd -r network
arch-chroot /mnt groupadd -r autologin
arch-chroot /mnt useradd -m -G network,autologin,input,kvm,floppy,audio,storage,uucp,wheel,optical,scanner,sys,video,disk -s /bin/bash "$user"
#create a temp file to store the password in and delete it when the script finishes using a trap
#https://www.pixelstech.net/article/1577768087-Create-temp-file-in-Bash-using-mktemp-and-trap
TMPFILE=$(mktemp) || exit 1
echo "$yellow""Storing password in temp file $TMPFILE to set the password - will be deleted on script completion""$reset"
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
#Lockout a user after 5 failed attempts for 10 mins
#unlock a user with: pam_tally2 --reset --user username
echo "#unlock a user account with: pam_tally2 --reset --user username" >> /mnt/etc/pam.d/system-login
echo "auth required pam_tally2.so deny=5 unlock_time=600 onerr=succeed file=/var/log/tallylog" >> /mnt/etc/pam.d/system-login
echo "$green""$user and password created - installing packages""$reset" && sleep 3s && clear


#Install repos - multilib, aurmageddon, archlinuxcn, archstrike and repo-ck
echo -e '[multilib]
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
#[archstrike]
#Server = https://mirror.archstrike.org/$arch/$repo
#Include = /etc/pacman.d/archstrike-mirrorlist
#[archstrike-testing]
#Include = /etc/pacman.d/archstrike-mirrorlist

#Repo containing custom compiled kernels with linux-ck
#[repo-ck]
#Server = http://repo-ck.com/$arch
#Server = http://repo-ck.com/$arch
#Server = http://repo-ck.com/$arch' >> /mnt/etc/pacman.conf


#reinstall keyring in case of gpg errors
arch-chroot /mnt pacman -Syy
arch-chroot /mnt pacman -S archlinux-keyring archlinuxcn-keyring --noconfirm
#install desktop and software
##add back pinta?
clear && echo "$green""Installing additional software""$reset" && sleep 1s
if [ "$desktop" = xfce ]; then
	arch-chroot /mnt pacman -S wget nano xfce4-panel xfce4-whiskermenu-plugin xfce4-taskmanager xfce4-cpufreq-plugin xfce4-pulseaudio-plugin xfce4-sensors-plugin conky xfce4-screensaver dialog lxdm network-manager-applet nm-connection-editor networkmanager-openvpn networkmanager libnm xfce4 yay grub-customizer baka-mplayer gparted gnome-disk-utility thunderbird nemo nemo-fileroller xfce4-terminal file-roller pigz lzip lrzip zip unzip p7zip htop libreoffice-fresh hunspell-en_US jdk11-openjdk jre11-openjdk zafiro-icon-theme transmission-gtk bleachbit galculator geeqie mpv gedit gedit-plugins papirus-icon-theme ttf-ubuntu-font-family ttf-ibm-plex bash-completion pavucontrol redshift youtube-dl ffmpeg atomicparsley ntp openssh gvfs-mtp cpupower ttf-dejavu ttf-symbola ttf-liberation noto-fonts pulseaudio-alsa xfce4-notifyd xfce4-screenshooter dmidecode macchanger systemd-swap pbzip2 smartmontools speedtest-cli neofetch net-tools xorg-xev dnsmasq downgrade nano-syntax-highlighting s-tui imagemagick libxpresent freetype2 rsync screen acpi keepassxc lxqt-policykit unrar bc bind-tools arch-install-scripts earlyoom arc-gtk-theme deadbeef ntfs-3g hardinfo memtest86+ --noconfirm
	arch-chroot /mnt pacman -S librewolf-bin arch-silence-grub-theme-git archlinux-lxdm-theme-full bibata-cursor-translucent imagewriter kernel-modules-hook matcha-gtk-theme-git nordic-theme-git pacman-cleanup-hook ttf-ms-fonts ttf-unifont update-grub materiav2-gtk-theme layan-gtk-theme-git lscolors-git --noconfirm
fi
clear && echo "$green""Installed programs - Enabling system services, generating configs""$reset"


#enable services and config lxdm
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable ntpdate
arch-chroot /mnt systemctl enable ctrl-alt-del.target
arch-chroot /mnt systemctl enable systemd-swap
arch-chroot /mnt systemctl enable earlyoom
arch-chroot /mnt systemctl enable lxdm
arch-chroot /mnt systemctl enable linux-modules-cleanup


#Enable fstrim if an ssd is detected using lsblk -d -o name,rota. Will return 0 for ssd
if lsblk -d -o name,rota | grep "0" > /dev/null 2>&1 ; then
	echo "$green""One or mode SSDs detected, enabling fstrim timer""$reset" && sleep 2s
	arch-chroot /mnt systemctl enable fstrim.timer
fi


#setup zram
sed "s,zswap_enabled=1,zswap_enabled=0,g" -i /mnt/etc/systemd/swap.conf
sed "s,zram_enabled=0,zram_enabled=1,g" -i /mnt/etc/systemd/swap.conf


#Determine if Vega 56 gpu and add gpuclock.service
#/sys/class/drm/card0/device also symbolic link to $amdid
#vega=$(lspci | grep 'Radeon RX Vega 56/64')
if lspci | grep 'Radeon RX Vega 56/64' || dmesg | grep amdgpu ; then
	echo "$green""AMD gpu found""$reset"
	arch-chroot /mnt pacman -S xf86-video-amdgpu --noconfirm
	arch-chroot /mnt pacman -S opencl-amd --noconfirm #Aurmageddon
else
	echo "$green""No AMD gpu installed - Installing intel driver""$reset"
	arch-chroot /mnt pacman -S xf86-video-intel libva-intel-driver --noconfirm
fi


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
echo "#$user ALL=(ALL) NOPASSWD:/usr/bin/pacman,/usr/bin/yay,/usr/bin/makepkg,/usr/bin/cpupower,/usr/bin/halt,/usr/bin/poweroff,/usr/bin/reboot" >> /mnt/etc/sudoers


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
sed "s,PKGEXT='.pkg.tar.xz',PKGEXT='.pkg.tar.zst',g" -i /mnt/etc/makepkg.conf


#If Entropy is low, install rng-tools
#rng-tools may not work well on older systems, so you may want to install https://wiki.archlinux.org/index.php/Haveged
entropy=$(cat /proc/sys/kernel/random/entropy_avail)
if [ "$entropy" -lt 1800 ]; then
	echo "Entropy under 1800, installing rng-tools" && sleep 2s
	arch-chroot /mnt pacman -S rng-tools --noconfirm
	arch-chroot /mnt systemctl enable rngd 
else
	echo "High entropy: $entropy"
fi


#create themes, disable recents, disable thunar in session - one time script to be started after creating inital xfce config
#Screensaver does not apply correctly - gets reset to 0 which is blank screen
#disable recents - https://alexcabal.com/disabling-gnomes-recently-used-file-list-the-better-way
#BEGIN NEW XFCE CONFIG!! yay
#Default wallpaper from manjaro forum
pacman -Syy
pacman -S unzip --noconfirm
wget https://github.com/wailord284/Arch-Linux-Installer/archive/master.zip
unzip master.zip
rm -r master.zip #we rm all dl stuff to make sure the live usb doesnt run out of space
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
#Default wallpaper
mv Arch-Linux-Installer-master/configs/ArchWallpaper.jpeg /mnt/usr/share/backgrounds/xfce/
#Take ownership
arch-chroot /mnt chown -R "$user":"$user" /home/"$user"/.config
arch-chroot /mnt chown -R "$user":"$user" /home/"$user"/.local/share
arch-chroot /mnt chown -R "$user":"$user" /home/"$user"/.gtkrc-2.0

#set fonts - https://www.reddit.com/r/archlinux/comments/5r5ep8/make_your_arch_fonts_beautiful_easily/
arch-chroot /mnt ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/10-hinting-full.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
sed "s,\#export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",g" -i /mnt/etc/profile.d/freetype2.sh
mv -f Arch-Linux-Installer-master/configs/fonts/local.conf /mnt/etc/fonts/local.conf


#NetworkManager/Network startup scripts
#interface=$(ip a | grep "state UP" | cut -c4- | sed 's/:.*//')
#configure mac address spoofing on startup via networkmanager
mkdir -p /mnt/etc/NetworkManager/conf.d/
mkdir -p /mnt/etc/NetworkManager/dnsmasq.d/
mv Arch-Linux-Installer-master/configs/networkmanager/rand_mac.conf /mnt/etc/NetworkManager/conf.d/
#IPv6 privacy and managed connection
echo -e "[connection]\nipv6.ip6-privacy=2\n[ifupdown]\nmanaged=true" >> /mnt/etc/NetworkManager/NetworkManager.conf
#Use dnsmasq for dns
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
mv -f Arch-Linux-Installer-master/configs/polkit-1/50-org.freedesktop.NetworkManager.rules /mnt/etc/polkit-1/rules.d/

#IOschedulers for storage that supposedly increase perfomance
mv Arch-Linux-Installer-master/configs/udev/60-ioschedulers.rules /mnt/etc/udev/rules.d/

#Udev PlatformIO needed for arduino uploading - https://docs.platformio.org/en/latest/faq.html#platformio-udev-rules
#arch-chroot /mnt wget https://raw.githubusercontent.com/platformio/platformio-core/master/scripts/99-platformio-udev.rules -P /etc/udev/rules.d/

#check and setup touchscreen - like x201T/x220T
if grep -i wacom /proc/bus/input/devices ; then
	echo "$green""Wacom found""$reset" && sleep 1s
	mv Arch-Linux-Installer-master/configs/xorg/72-wacom-options.conf /mnt/etc/X11/xorg.conf.d/
fi
#Check and setup touchpad
if grep -i TouchPad /proc/bus/input/devices || arch-chroot /mnt acpi -i | grep -E "Battery[0-9]" ; then
	echo "$green""Touchpad or battery found - setting up synaptics driver and power saving""$reset" && sleep 1s
	arch-chroot /mnt pacman -S x86_energy_perf_policy xf86-input-synaptics ethtool tlp tlp-rdw --noconfirm
	mv Arch-Linux-Installer-master/configs/xorg/70-synaptics.conf /mnt/etc/X11/xorg.conf.d/
	#USB autosuspend
	echo 'ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"' > /mnt/etc/udev/rules.d/50-usb_power_save.rules
	echo "options usbcore autosuspend=5" > /mnt/etc/modprobe.d/usb-autosuspend.conf
	#HDD power save
	echo 'ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"' > /mnt/etc/udev/rules.d/hd_power_save.rules
	#Laptop mode to save power with spinning drives
	echo "vm.laptop_mode = 5" > /mnt/etc/sysctl.d/00-laptop-mode.conf
	arch-chroot /mnt systemctl enable tlp.service
fi

#Blacklist uncommon modules/protocols
mv Arch-Linux-Installer-master/configs/modprobe/blacklist-uncommon-network-protocols.conf /mnt/etc/modprobe.d/
#load the tcp_bbr module for better network stuffs
echo 'tcp_bbr' > /mnt/etc/modules-load.d/tcp_bbr.conf

#enable autologin and session
sed "s,\#\ session=/usr/bin/startlxde,\ session=/usr/bin/startxfce4,g" -i /mnt/etc/lxdm/lxdm.conf
sed "s,theme=Industrial,theme=Archlinux,g" -i /mnt/etc/lxdm/lxdm.conf
sed "s,gtk_theme=Adwaita,gtk_theme=Nordic,g" -i /mnt/etc/lxdm/lxdm.conf

#Netfilter connection tracker
echo "options nf_conntrack nf_conntrack_helper=0" > /mnt/etc/modprobe.d/no-conntrack-helper.conf
#Set wifi region
sed "s,\#WIRELESS_REGDOM=\"US\",WIRELESS_REGDOM=\"US\",g" -i /mnt/etc/conf.d/wireless-regdom


#Setup sysctl tweaks
#disables watchdog
##No longer enabled by default. May be useful to leave for servers
#mv Arch-Linux-Installer-master/configs/sysctl/00-disable-watchdog.conf /mnt/etc/sysctl.d/

#unprivileged_userns_clone
mv Arch-Linux-Installer-master/configs/sysctl/00-unprivileged-userns.conf /mnt/etc/sysctl.d/

#fix usb speeds
mv Arch-Linux-Installer-master/configs/sysctl/00-usb-speed-fix.conf /mnt/etc/sysctl.d/

#ipv6 privacy
mv Arch-Linux-Installer-master/configs/sysctl/00-ipv6-privacy.conf /mnt/etc/sysctl.d/

#kernel hardening
mv Arch-Linux-Installer-master/configs/sysctl/00-kernel-hardening.conf /mnt/etc/sysctl.d/

#link restrictions
mv Arch-Linux-Installer-master/configs/sysctl/00-link-restrictions.conf /mnt/etc/sysctl.d/

#system tweaks
mv Arch-Linux-Installer-master/configs/sysctl/30-system-tweak.conf /mnt/etc/sysctl.d/

#network tweaks
mv Arch-Linux-Installer-master/configs/sysctl/30-network.conf /mnt/etc/sysctl.d/
clear && echo "$green""Set configs - configuring Grub""$reset" && sleep 2s


#grub install
if [ "$boot" = efi ]; then
	arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --removable --recheck
fi

if [[ -z "$boot" ]]; then
	arch-chroot /mnt grub-install --target=i386-pc "$storage" --recheck
fi


#add custom menus to grub
#https://wiki.archlinux.org/index.php/GRUB#EFI_binaries
####ADD - BIOS FLASH/AMDVbflash
#Custom grub binaries - gdisk, uefi shell, flappybird and tetris
#add gdisk menu - https://wiki.archlinux.org/index.php/GPT_fdisk#gdisk_EFI_application
pacman -S p7zip --noconfirm
###TOOLS###
#Grub file manager https://github.com/a1ive/grub2-filemanager/releases
wget https://github.com/a1ive/grub2-filemanager/releases/latest/download/grubfm-en_US.7z
7z x grubfm-en_US.7z
mkdir -p /mnt/boot/EFI/tools
mv grubfmx64.efi grubfm.iso loadfm /mnt/boot/EFI/tools/
rm -r grubfm-en_US.7z grubfmia32.efi
#uefi shell V1/V2 https://github.com/tianocore/edk2/blob/UDK2018/EdkShellBinPkg/
wget https://github.com/tianocore/edk2/releases/latest/download/ShellBinPkg.zip
wget https://github.com/tianocore/edk2/raw/UDK2018/EdkShellBinPkg/MinimumShell/X64/Shell.efi
unzip ShellBinPkg.zip
mv ShellBinPkg/UefiShell/X64/Shell.efi /mnt/boot/EFI/tools/shellx64_v2.efi
mv Shell.efi /mnt/boot/EFI/tools/shellx64_v1.efi
rm -r ShellBinPkg.zip ShellBinPkg
#gdisk - https://sourceforge.net/projects/gptfdisk/files/gptfdisk/
gdiskVersion="1.0.4"
wget https://cfhcable.dl.sourceforge.net/project/gptfdisk/gptfdisk/"$gdiskVersion"/gdisk-binaries/gdisk-efi-"$gdiskVersion".zip
unzip gdisk-efi-"$gdiskVersion".zip
mv gdisk-efi/gdisk_x64.efi /mnt/boot/EFI/tools/
rm -r gdisk-efi-"$gdiskVersion".zip gdisk-efi
#RU - Universal Chipset Reading # password 2002118028047
#https://ruexe.blogspot.com/
wget https://github.com/JamesAmiTw/ru-uefi/raw/master/5.25.0379.zip
unzip -P 2002118028047 5.25.0379.zip
mv RU.efi /mnt/boot/EFI/tools/ru.efi
rm -r RU.EXE RU32.efi 5.25.0379.zip
#Memtest86 - UEFI. Legacy BIOS handled by memtest86+ package
#mount the img file on the target install to not run out of disk space
#once mounted, we extract the UEFI bootable files
wget https://www.memtest86.com/downloads/memtest86-usb.zip -P /mnt/memtest
unzip /mnt/memtest/memtest86-usb.zip -d /mnt/memtest/
mkdir -p /mnt/memtest/memimg
#offset = 512*2048
mount -o loop,offset=1048576 /mnt/memtest/memtest86-usb.img /mnt/memtest/memimg
mv /mnt/memtest/memimg/EFI/BOOT/BOOTX64.efi /mnt/boot/EFI/tools/memtestx64.efi
umount /mnt/memtest/memimg
rm -r /mnt/memtest
#UEFIDiskBenchmark https://github.com/manusov/UEFIdiskBenchmark
wget https://github.com/manusov/UEFIdiskBenchmark/blob/master/executable/UefiDiskBenchmark.efi
mv UefiDiskBenchmark.efi /mnt/boot/EFI/tools/diskbenchmark.efi
###GAMES###
#FlappyBird
mkdir -p /mnt/boot/EFI/games
wget https://raw.githubusercontent.com/hymen81/UEFI-Game-FlappyBirdy/master/binary/FlappyBird.efi
mv FlappyBird.efi /mnt/boot/EFI/games/
#Tetris
wget https://github.com/manusov/UEFImarkAndTetris64/raw/master/executable/TETRIS.EFI
wget https://github.com/a1ive/uefi-tetris/blob/master/tetris.efi
mv TETRIS.EFI /mnt/boot/EFI/games/tetris.efi
mv tetris.efi /mnt/boot/EFI/games/tetrisClassic.efi
#UEFIBoy https://github.com/RossMeikleham/UEFIBoy/
wget https://github.com/RossMeikleham/UEFIBoy/releases/download/0.1.0/Plutoboy.efi
wget -nc -nv -U "eye01" https://the-eye.eu/public/rom/Nintendo%20Gameboy/Galaga%20%26%20Galaxian%20%28U%29%20%5BS%5D%5B%21%5D.zip -O galaga.zip
unzip galaga.zip
mv "Galaga & Galaxian (U) [S][!].gb" /mnt/boot/EFI/games/autoload.rom
mv Plutoboy.efi /mnt/boot/EFI/games/
#Create /boot/grub/bustom.cfg
mv Arch-Linux-Installer-master/configs/grub/custom.cfg /mnt/boot/grub/

#Weird PCIE errors for X99 - https://unix.stackexchange.com/questions/327730/what-causes-this-pcieport-00000003-0-pcie-bus-error-aer-bad-tlp
#grub config and unmount - https://make-linux-fast-again.com/ - nowatchdog pci=nommconf intel_pstate=disable acpi-cpufreq
mitigations=$(curl https://make-linux-fast-again.com/)
#sed "s,\GRUB_TIMEOUT=5,\GRUB_TIMEOUT=3,g" -i /mnt/etc/default/grub
echo 'GRUB_THEME="/boot/grub/themes/arch-silence/theme.txt"' >> /mnt/etc/default/grub
if [[ "$boot" = efi && "$encrypt" = y ]]; then
	uuid=$(lsblk -dno UUID "${storagePartitions[2]}")
	#sed "s,\#\GRUB_ENABLE_CRYPTODISK="'"y"'",GRUB_ENABLE_CRYPTODISK="'"y"'",g" -i /mnt/etc/default/grub
	sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$uuid:cryptroot root=/dev/mapper/cryptroot audit=0 loglevel=3 $mitigations\",g" -i /mnt/etc/default/grub
fi
if [[ -z "$boot" && "$encrypt" = y ]]; then
	uuid=$(lsblk -dno UUID "${storagePartitions[2]}")
	#sed "s,\#\GRUB_ENABLE_CRYPTODISK="'"y"'",GRUB_ENABLE_CRYPTODISK="'"y"'",g" -i /mnt/etc/default/grub
	sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$uuid:cryptroot root=/dev/mapper/cryptroot audit=0 loglevel=3 $mitigations\",g" -i /mnt/etc/default/grub
fi
#generate grubcfg if no encryption as theyre the same
if [ "$encrypt" = n ]; then
	sed "s,\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\",\GRUB_CMDLINE_LINUX_DEFAULT=\"audit=0 loglevel=3 $mitigations\",g" -i /mnt/etc/default/grub
fi
#generate grubcfg
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
clear


#optional post install settings
declare -a selection
while : ;do
echo "$green""Installation complete! Here are some optional things you may want to install:""$reset"
echo "$green""1$reset - Install Bedrock Linux"
echo "$green""2$reset - Enable X2Go remote management server"
echo "$green""3$reset - Enable sshd"
echo "$green""4$reset - Route all traffic over Tor"
echo "$green""5$reset - Sort mirrors with Reflector $green(recommended)"
echo "$green""6$reset - Enable and install the UFW firewall"
echo "$green""7$reset - Use the iwd wifi backend over wpa_suplicant for NetworkManager $green(recommended)"
echo "$green""8$reset - Restore old network interface names (eth0, wlan0...)"
echo "$green""9$reset - Disable/blacklist bluetooth and webcam $green(recommended)"
echo "$green""10$reset - Enable Firejail for all supported applications"
echo "$green""11$reset - Enable vnstat webui traffic monitor"
echo "$green""12$reset - Enable local Searx search engine"
echo "$green""13$reset - Install the proprietary NVidia GPU driver"
echo "$green""14$reset - Enable AMD Freesync - Might break Xorg"
echo "$green""15$reset - Enable automatic desktop login in lxdm $green(recommended)"
echo "$green""16$reset - Add LibreDNS in systemd-resolved - Not enabled by default"
echo "$green""17$reset - Enable Ananicy - Daemon for setting CPU priority and scheduling. May increase performance"
echo "$green""18$reset - Block ads system wide using hblock to modify the hosts file $green(recommended)"
echo "$green""19$reset - Enable IRQBalance - helps balance the cpu load generated by interrupts across all of a systems cpus"
echo "$green""20$reset - Enable Haveged - increase system entropy and randomness"

echo "$reset""Default options are:$green 5 7 9 15 18$red q""$reset"
echo "Enter$green 1-20$reset (seperated by spaces for multiple options including (q)uit) or$red q$reset to$red quit$reset"
read -r -p "Options: " selection
selection=${selection:- 5 7 9 15 18 q}
	for entry in $selection ;do

	case "${entry[@]}" in

		1)
		#bedrock - https://raw.githubusercontent.com/bedrocklinux/bedrocklinux-userland/0.7/releases
		bedrockVersion="0.7.17"
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
		arch-chroot /mnt pacman -S autossh --noconfirm #installed from Aurmageddon
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
		echo -e 'port=53
no-resolv
server=127.0.0.1#9053
listen-address=127.0.0.1
cache-size=1000' >> /mnt/etc/dnsmasq.conf

		arch-chroot /mnt systemctl enable iptables.service
		arch-chroot /mnt systemctl enable ip6tables.service
		arch-chroot /mnt usermod -a -G tor "$user"
		sleep 3s
		;;

		5)
		echo "$green""Sorting mirrors""$reset"
		arch-chroot /mnt pacman -S reflector --noconfirm
		arch-chroot /mnt reflector --verbose --latest 200 --country US --protocol http --protocol https --age 12 --sort rate --save /etc/pacman.d/mirrorlist
		sed '/mirror.lty.me/d' -i /mnt/etc/pacman.d/mirrorlist
		sed '/mirrors.kernel.org/d' -i /mnt/etc/pacman.d/mirrorlist
		sleep 3s
		;;

		6)
		echo "$green""Installing and configuring the UFW firewall""$reset"
		arch-chroot /mnt pacman -S ufw gufw --noconfirm
		arch-chroot /mnt ufw default deny
		arch-chroot /mnt ufw allow Transmission
		arch-chroot /mnt ufw limit ssh
		arch-chroot /mnt ufw enable
		arch-chroot /mnt systemctl enable ufw.service
		sleep 3s
		;;

		7)
		echo "$green""Configuring iwd as the default wifi backend in NetworkManager""$reset"
		mv Arch-Linux-Installer-master/configs/networkmanager/wifi_backend.conf /mnt/etc/NetworkManager/conf.d/
		arch-chroot /mnt pacman -S iwd --noconfirm
		arch-chroot /mnt systemctl enable iwd
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
		echo "Do you want the$green open (xf86-video-nouveau)$reset or$red closed (nvidia-dkms) driver""$reset"
		echo "Enter$green open$reset or$red closed""$reset"
		echo "If you play video games, you'll likely want the closed driver"
		read -r -p "open or close?: " nvidia
		if [ "$nvidia" = open ]; then
			echo "$green""Installing free driver""$reset"
			arch-chroot /mnt pacman -S xf86-video-nouveau --noconfirm
		else
			echo "$red""Installing proprietary garbage""$reset"
			arch-chroot /mnt pacman -S nvidia-dkms nvidia-settings libxnvctrl --noconfirm
		fi
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
		#https://libredns.gr/
		echo "$green""Adding LibreDNS - https://libredns.gr/""$reset"
		echo -e 'DNS=116.203.115.192
FallbackDNS=1.1.1.1 1.0.0.1 9.9.9.9
Cache=yes
DNSOverTLS=yes' >> /etc/systemd/resolved.conf 
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
		#IRQbalance
		echo "$green""Installing and enabling IRQBalance""$reset"
		arch-chroot /mnt pacman -S irqbalance --noconfirm
		arch-chroot /mnt systemctl enable irqbalance.service
		sleep 3s
		;;

		20)
		#https://wiki.archlinux.org/index.php/Haveged
		if [ "$entropy" -lt 1800 ]; then
			echo "$yellow""rng-tools was already installed after low entropy was detected""$reset"
			echo "$yellow""Would you like to remove rng-tools and install haveged? - y/n"
			read -r -p "Install Haveged: " haveged
			if [ "$haveged" = y ]; then
				echo "$green""Disabling rng-tools and installing Haveged to increase system entropy""$reset"
				arch-chroot /mnt pacman -S haveged --noconfirm
				arch-chroot /mnt systemctl disable rngd.service
				arch-chroot /mnt systemctl enable haveged.service
			else
				echo "$green""Keeping rng-tools installed""$reset"
			fi
		else
			echo "$green""Installing Haveged to increase system entropy""$reset"
			arch-chroot /mnt pacman -S haveged --noconfirm
			arch-chroot /mnt systemctl enable haveged.service
		fi
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
		echo "$green""Thanks for installing! Reboot to complete installation.""$reset"
		sleep 3s
		exit 0
		;;
	esac
	done
done
