#!/bin/sh

. /puppet/metalib/bin/lib.sh

RUNNIG=$(iptables-save | grep INPUT | grep -v "f2b\-" |  wc -l | awk '{print $1}')
CONFIG=$(cat /var/lib/iptables/active | grep INPUT | wc -l | awk '{print $1}')

if [ "x$RUNNIG" != "x$CONFIG" ]; then
	rreturn 1 "$0 running firewall differs from config"
fi



RUNNIG=$(ip6tables-save | grep INPUT | grep -v "f2b\-" | wc -l | awk '{print $1}')
CONFIG=$(cat /var/lib/ip6tables/active | grep INPUT | wc -l | awk '{print $1}')

if [ "x$RUNNIG" != "x$CONFIG" ]; then
	rreturn 1 "$0 running firewall6 differs from config"
fi


rreturn 0 "$0"

