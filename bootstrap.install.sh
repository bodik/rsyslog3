#!/bin/sh

apt-get update
apt-get install -y git puppet

if [ ! -d /puppet ]; then
	cd /
	git clone https://haas.cesnet.cz/haas.git
	ln -sf /haas /puppet
else
	cd /puppet
	git remote set-url origin https://haas.cesnet.cz/haas.git
	git pull
fi

cd /puppet && git remote set-url origin dev@haas.cesnet.cz:/data/haas.git

