#!/usr/bin/env bash
#Snapper doesnt run in chroot due to dbus errors
#In order to setup our snapshots correctly, we make a one time boot script
#Create our snapper config
snapper -c root create-config /
#Change snapper backups to keep to 25
sed "s,NUMBER_LIMIT=\"50\",NUMBER_LIMIT=\"25\",g" -i /etc/snapper/configs/root
#Change snapper timeline settings to keep 0 hourly, 5 daily, 3 weekly and 1 monthly
sed "s,TIMELINE_LIMIT_HOURLY=\"10\",TIMELINE_LIMIT_HOURLY=\"0\",g" -i /etc/snapper/configs/root
sed "s,TIMELINE_LIMIT_DAILY=\"10\",TIMELINE_LIMIT_DAILY=\"5\",g" -i /etc/snapper/configs/root
sed "s,TIMELINE_LIMIT_WEEKLY=\"0\",TIMELINE_LIMIT_WEEKLY=\"3\",g" -i /etc/snapper/configs/root
sed "s,TIMELINE_LIMIT_MONTHLY=\"10\",TIMELINE_LIMIT_MONTHLY=\"1\",g" -i /etc/snapper/configs/root
sed "s,TIMELINE_LIMIT_YEARLY=\"10\",TIMELINE_LIMIT_YEARLY=\"0\",g" -i /etc/snapper/configs/root
#Enable snapper system services. Cleanup and time based snapshots
systemctl enable snapper-cleanup.timer snapper-timeline.timer
#Disable the snapper config script
systemctl disable snapper-frstboot.service