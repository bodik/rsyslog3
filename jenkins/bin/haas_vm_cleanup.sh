#!/bin/sh

echo "INFO: base VM cleanup"
systemctl stop avahi-daemon.socket avahi-daemon.service
systemctl stop cron
systemctl stop postfix
systemctl stop ntp
systemctl stop atopacct
systemctl stop dbus.socket dbus.service
systemctl stop syslog.socket rsyslog.service

apt-get clean

/usr/sbin/logrotate -f /etc/logrotate.conf
find /var/log -type f -name '*gz' -exec shred --force --remove {} \;
find /var/log -type f -name '*.1' -exec shred --force --remove {} \;
find /var/log -type f -exec shred --force {} \;
find /var/log -type f -exec truncate --size 0 {} \;

find /var/backups -type f -exec shred --force --remove {} \;

find /var/tmp -type f -exec shred --force --remove {} \;
find /tmp -type f -exec shred --force --remove {} \;
rm -rf /tmp/*
rm -rf /var/tmp/*

find /root -type f ! -name authorized_keys ! -name .bashrc ! -name .profile ! -name .vimrc -exec shred --force --remove {} \;


# call all others cleanups from modules
find /puppet/ -type f -name "vm_cleanup.sh" -exec sh {} \;

