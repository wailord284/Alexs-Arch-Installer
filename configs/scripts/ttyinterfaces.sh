#!/usr/bin/env bash
#Add the default Arch prompt and clear the old prompts
echo "Arch Linux \r (\l)" > /etc/issue
echo "Hostname: \n" >> /etc/issue
echo "Today is: \d" >> /etc/issue
echo "The time is: \t" >> /etc/issue
echo "" >> /etc/issue

#Use our own network connectivity check
#Check if we can access archlinux.com 10 tens, once a minute
#If after 10 tries, fail. Otherwise, output IP addresses
counter=0
while : ; do
	sleep 60s
	curl -s -o /dev/null http://archlinux.com
	if [ $? -eq 1 ]; then
		((counter++))
		if [ "$counter" = 10 ]; then
			echo "No Internet connection established after 10 minutes." >> /etc/issue
			echo "Unable to get IP addresses." >> /etc/issue
			break && exit 1
		fi
	else
		#Output a list of all interfaces to /etc/issue
		for interface in /sys/class/net/* ; do
			baseInt=$(basename "$interface")
			echo "IPv4 Address for $baseInt: \4{$baseInt}" >> /etc/issue
		done
		break
	fi
done

#Finish by adding an extra newline to have the prompt one empty line down
echo -e "\n" >> /etc/issue
