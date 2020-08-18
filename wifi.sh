#!/bin/bash
HEIGHT=24
WIDTH=80
#WIDTH=0 #0 auto sets
CHOICE_HEIGHT=10
dialogBacktitle="Alex's Arch Linux Installer"
dialogHeight=20
dialogWidth=80
#https://wiki.archlinux.org/index.php/Iwd#iwctl
#Device name
COUNT=0
for i in $(iw dev | grep "Interface" | cut -d ' ' -f2) ; do
	COUNT=$((COUNT+1))
	MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
done
wifichoice=(dialog --backtitle "$dialogBacktitle" \
	--title "Select your wireless device" \
	--scrollbar \
	--radiolist "Press space to select your wireless device" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
options=(${MENU_OPTIONS})
wifidev=$("${wifichoice[@]}" "${options[@]}" 2>&1 >/dev/tty)

#SSID
unset COUNT MENU_OPTIONS options
COUNT=0
for i in $(sudo iw dev wlan0 scan | grep "SSID:" | cut -d ' ' -f2) ; do
	COUNT=$((COUNT+1))
	MENU_OPTIONS="${MENU_OPTIONS} $i ${COUNT} off"
done
ssidchoice=(dialog --backtitle "$dialogBacktitle" \
	--title "Select your wireless network" \
	--scrollbar \
	--radiolist "Press space to select your wireless access point" "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT")
options=(${MENU_OPTIONS})
ssid=$("${ssidchoice[@]}" "${options[@]}" 2>&1 >/dev/tty)

wifipass=$(dialog --title "Wireless password" \
	--backtitle "$dialogBacktitle" \
	--passwordbox "Please enter the password for $ssid (password hidden)" "$dialogHeight" "$dialogWidth" 2>&1 > /dev/tty)
clear
iwctl --passphrase "$wifipass" station "$wifidev" connect "$ssid"

echo "You are now connected to $ssid"
