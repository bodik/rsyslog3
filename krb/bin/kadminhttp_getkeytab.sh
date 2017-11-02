#!/bin/sh

curl --output /etc/krb5.keytab "http://$(/puppet/metalib/bin/avahi_findservice.sh _kdc._udp):47900/get_keytab"
chmod 600 /etc/krb5.keytab
