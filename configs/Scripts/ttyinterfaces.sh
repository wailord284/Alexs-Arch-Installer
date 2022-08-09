#!/usr/bin/env bash
#Wait 60 seconds in case the user needs to login or the network needs to connect
sleep 60s
#Add the default Arch prompt and clear the old addresses
echo "Arch Linux \r (\l)" > /etc/issue
echo "Hostname: \n" >> /etc/issue
echo "Today is: \d" >> /etc/issue
echo "The time is: \t" >> /etc/issue
echo "" >> /etc/issue
#Output a list of all interfaces to /etc/issue
for interface in $(ls /sys/class/net/) ; do
	echo "IPv4 Address for $interface: \4{$interface}" >> /etc/issue
done
echo -e "\n" >> /etc/issue
