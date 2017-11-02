#!/bin/sh

set -e

KDC="$1"
curl --fail --output /etc/krb5.keytab "http://${KDC}:47900/get_keytab"
chmod 600 /etc/krb5.keytab
