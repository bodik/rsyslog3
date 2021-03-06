#!/bin/sh

apt-get update
apt-get install -y git puppet

if [ ! -d /puppet ]; then
	cd /
	git clone https://rsyslog.metacentrum.cz/rsyslog3.git
	ln -sf /rsyslog3 /puppet
else
	cd /puppet
	git remote set-url origin https://rsyslog.metacentrum.cz/rsyslog3.git
	git pull
fi

cd /puppet && git remote set-url origin bodik@rsyslog.metacentrum.cz:/data/rsyslog3.git

