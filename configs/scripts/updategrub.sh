#!/usr/bin/env bash
##We have to do this now since the Arch devs did not test or announce grub issues for several days after an incident occured.
##To prevent future issues, we always reinstall and then update grub anytime grub updates.
echo "Grub update found! Reinstalling and updating grub config..."
#If efi is present in /sys/firmware/ then system is UEFI
#Find the root disk for reinstalling with BIOS. UEFI uses /boot in the install script and is always mounted
if [ -d /sys/firmware/efi/ ]; then
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable --recheck
else
	rootDisk=$(df -hT | grep /$ | cut -d" " -f1)
	grub-install --target=i386-pc "$rootDisk" --recheck
fi
#Update grub config
grub-mkconfig -o /boot/grub/grub.cfg