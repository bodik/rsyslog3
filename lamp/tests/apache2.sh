#!/bin/sh

. /puppet/metalib/bin/lib.sh

#installation
/usr/lib/nagios/plugins/check_procs --argument-array=/usr/sbin/apache2 -c 10:
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 check_procs"
fi

netstat -nlpa | grep "/apache2" | grep LISTEN | grep :80
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 http listener"
fi

netstat -nlpa | grep "/apache2" | grep LISTEN | grep :443
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 https listener"
fi




#basic virtualhosts
curl --silent "http://$(facter fqdn)" | grep 'HaaS cesnet.cz'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 http index.php"
fi

curl --insecure --silent "https://$(facter fqdn)" | grep 'HaaS cesnet.cz'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 http index.php"
fi





for all in $(facter fqdn) $(facter ipaddress); do
	curl --silent --include "http://${all}/statusek" | head -1 | grep '^HTTP/1.1 404 Not Found'
	if [ $? -ne 0 ]; then
		rreturn 1 "$0 apache2 http ${all} /statusek maskforbidden check"
	fi
done

curl --silent --include "http://127.0.0.1/statusek" | head -1 | grep '^HTTP/1.1 200 OK'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 http localhost /statusek check"
fi





TMPFILE=$(mktemp)
curl --insecure --silent --include "https://$(facter fqdn)/statusek" > ${TMPFILE}
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 https /statusek fetch"
fi

grep '^X-Frame-Options: sameorigin' ${TMPFILE}
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 sameorigin"
fi

grep 'Server MPM: prefork' ${TMPFILE}
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 mpm model"
fi

rm -f ${TMPFILE}



rreturn 0 "$0"
