#!/usr/bin/env bash
#Snapper doesnt run in chroot due to dbus errors
#In order to setup our snapshots correctly, we make a one time boot script
#Create our snapper config
snapper -c root create-config /
#Change snapper backups to keep to 15
sed "s,NUMBER_LIMIT=\"50\",NUMBER_LIMIT=\"15\",g" -i /etc/snapper/configs/root
#Change snapper timeline settings to keep 3 daily and 1 weekly. We dont enable the service though
sed "s,TIMELINE_LIMIT_HOURLY=\"10\",TIMELINE_LIMIT_HOURLY=\"0\",g" -i /etc/snapper/configs/root
sed "s,TIMELINE_LIMIT_DAILY=\"10\",TIMELINE_LIMIT_DAILY=\"3\",g" -i /etc/snapper/configs/root
sed "s,TIMELINE_LIMIT_WEEKLY=\"0\",TIMELINE_LIMIT_WEEKLY=\"1\",g" -i /etc/snapper/configs/root
sed "s,TIMELINE_LIMIT_MONTHLY=\"10\",TIMELINE_LIMIT_MONTHLY=\"0\",g" -i /etc/snapper/configs/root
sed "s,TIMELINE_LIMIT_YEARLY=\"10\",TIMELINE_LIMIT_YEARLY=\"0\",g" -i /etc/snapper/configs/root
#Disable timeline snapshots
sed "s,TIMELINE_CREATE=\"yes\",TIMELINE_CREATE=\"no\",g" -i /etc/snapper/configs/root
#Enable snapper system services for cleanup
systemctl enable snapper-cleanup.timer
#Disable the snapper config script
systemctl disable snapper-firstboot.service