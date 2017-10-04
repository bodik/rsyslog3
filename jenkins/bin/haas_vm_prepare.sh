#!/bin/sh

# Regenerate ssh keys
rm -f /etc/ssh/*_key*
dpkg-reconfigure openssh-server

# update basic node sessintgs (mainly hostname/fqdn)
cd /puppet && sh phase2.install.sh

# Delayled reboot
echo "\n\nWARN: Reboot in 5 seconds!\n\n"
sync
sleep 5
reboot 
