#!/usr/bin/env bash
##We have to do this now since the Arch devs did not test or announce grub issues for several days after an incident occured.
##To prevent future issues, we always reinstall and then update grub anytime grub updates.
echo -e "\nGrub update found! Reinstalling and updating grub config..."
#If efi is present in /sys/firmware/ then system is UEFI
#Find the root disk for reinstalling with BIOS. UEFI uses /boot in the install script and is always mounted
if [ -d /sys/firmware/efi/ ]; then
	if [ "$(cat /sys/firmware/efi/fw_platform_size)" = 64 ]; then
		grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable --recheck
	else
		grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=GRUB --removable --recheck
	fi
else
	#Get the disk mounted at /boot
	bootDisk=$(df -hT | grep /boot$ | cut -d" " -f1)
	#Get the root disk without partitions
	if [[ "$bootDisk" = /dev/nvme* ]] || [[ "$bootDisk" = /dev/mmcblk* ]]; then
		rootDisk=$(echo "$bootDisk" | cut -c-12)
	elif [[ "$bootDisk" = /dev/vd* ]] || [[ "$bootDisk" = /dev/sd* ]]; then
		rootDisk=$(echo "$bootDisk" | cut -c-8)
	fi
	#Reinstall grub to the rootDisk
	grub-install --target=i386-pc "$rootDisk" --recheck
fi
#Update grub config
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "\nGrub update complete!"