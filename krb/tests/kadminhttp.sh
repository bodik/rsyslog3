#!/bin/sh

. /puppet/metalib/bin/lib.sh

/usr/lib/nagios/plugins/check_procs --argument-array="/usr/bin/python /opt/kadminhttp/kadminhttp.py" -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 kadminhttp check_procs"
fi
netstat -nlpa | grep "/python " | grep LISTEN | grep :47900
if [ $? -ne 0 ]; then
	rreturn 1 "$0 kadminhttp listener"
fi

