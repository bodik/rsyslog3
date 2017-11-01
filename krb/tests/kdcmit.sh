#!/bin/sh

. /puppet/metalib/bin/lib.sh


/usr/lib/nagios/plugins/check_procs --argument-array=/usr/sbin/krb5kdc -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 krb5kdc check_procs"
fi
/usr/lib/nagios/plugins/check_procs --argument-array=/usr/sbin/kadmind -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 kadmin check_procs"
fi

SERVICE=_krb5kdc._udp
avahi-browse -t $SERVICE --resolve -p | grep $(facter ipaddress)
if [ $? -ne 0 ]; then
	rreturn 1 "$0 _krb5kdc._udp not found"
fi


sh /puppet/krb/tests/kadminhttp.sh

rreturn 0 "$0"
