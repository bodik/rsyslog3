#!/bin/sh

if [ -z $1 ]; then
	REALM=$(cat /etc/krb5.conf  | grep default_realm | awk '{print $3}')
else
	REALM=$1
fi

KRB5_CONFIG=/etc/heimdal-kdc/kdc.conf kadmin.heimdal --local --realm=$REALM list -s --column-info=principal,kvno,keytypes '*'
