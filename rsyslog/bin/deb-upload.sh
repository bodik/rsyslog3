#!/bin/sh

FRONT='bodik@rsyslog.metacentrum.cz'
REPO="/data/rsyslog3-packages"

cd /tmp/build-area

dpkg-scanpackages ./ /dev/null | gzip > Packages.gz

ssh $FRONT "find ${REPO} -type f -delete"
scp * ${FRONT}:${REPO}/
# >>> deb https://rsyslog.metacentrum.cz/rsyslog3-packages ./



