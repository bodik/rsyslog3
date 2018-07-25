#!/bin/sh

DESTDIR="/etc/apache2/ssl"
FQDN="$(facter fqdn)"
USERNAME=""
if [ -n "$1" ]; then DESTDIR="$1"; fi
if [ -n "$2" ]; then FQDN="$2"; fi
if [ -n "$3" ]; then USERNAME="$3"; fi


if [ -f "${DESTDIR}/${FQDN}.key" ]; then
        echo "ERROR: key ${DESTDIR}/${FQDN}.key already present"
        exit 1
fi

echo "INFO: generating sel-signed ${DESTDIR}/${FQDN}.key"
mkdir -p "${DESTDIR}"

cat > "${DESTDIR}/${FQDN}.cfg" << __EOF__
[req]
default_bits = 4096
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = req_ext
prompt = no

[req_distinguished_name]
commonName = '${FQDN}'

[req_ext]
subjectAltName = 'DNS.1:${FQDN}'
__EOF__

openssl req -new -newkey rsa -nodes -x509 -days 365 -keyout "${DESTDIR}/${FQDN}.key" -out "${DESTDIR}/${FQDN}.crt" -config "${DESTDIR}/${FQDN}.cfg"
cat "${DESTDIR}/${FQDN}.key" "${DESTDIR}/${FQDN}.crt" > "${DESTDIR}/${FQDN}.bundle"

find "${DESTDIR}" -type f -exec chmod 640 {} \;
if [ -n $USERNAME ]; then
	find "${DESTDIR}" -exec chown ${USERNAME}:${USERNAME} {} \;
fi
