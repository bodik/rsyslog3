#!/bin/sh

. /puppet/metalib/bin/lib.sh


/usr/lib/nagios/plugins/check_procs --argument-array=/usr/lib/heimdal-servers/kdc -c 1:
if [ $? -ne 0 ]; then
	rreturn 1 "$0 heimdal-servers/kdc check_procs"
fi
/usr/lib/nagios/plugins/check_procs --argument-array=inetd -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 kadmin check_procs"
fi

sh /puppet/krb/tests/kadminhttp.sh

rreturn 0 "$0"
