#!/bin/sh

if [ -z $1 ]; then
	echo "ERROR: no service specified"
	exit 1
fi

which avahi-browse 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	puppet apply --modulepath=/puppet:/puppet/3rdparty -e 'include metalib::avahi' 1>/dev/null 2>/dev/null
fi

QUERY=$(avahi-browse -t $1 --resolve -p | grep "=;.*;IPv4;")
if [ -n "${QUERY}" ]; then
	IP=$(echo ${QUERY} | awk -F";" '{print $8}' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1)
	URL=$(echo ${QUERY} | grep ${IP} | awk -F";" '{print $10}' | sed 's/\"//g' | awk -F"=" '{print $2}')
fi

if [ -z $URL ]; then
        exit 0
else
	echo $URL
        exit 0
fi

