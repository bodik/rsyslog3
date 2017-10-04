#!/bin/sh

DESTDIR=/etc/apache2/ssl
FQDN=$(facter fqdn)
if [ -n "$1" ]; then DESTDIR="$1"; fi
if [ -n "$2" ]; then FQDN="$2"; fi


if [ -f "${DESTDIR}/${FQDN}.key" ]; then
        echo "ERROR: key ${DESTDIR}/${FQDN}.key already present"
        exit 1
fi

echo "INFO: generating sel-signed ${DESTDIR}/${FQDN}.key"
mkdir -p "${DESTDIR}"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -keyout "${DESTDIR}/${FQDN}.key" -out "${DESTDIR}/${FQDN}.crt" -subj "/CN=${FQDN}/"
find "${DESTDIR}" -type f -exec chmod 640 {} \;

