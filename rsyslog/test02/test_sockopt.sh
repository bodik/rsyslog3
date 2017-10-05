#!/bin/sh

set -e

. /puppet/metalib/bin/lib.sh

if [ -z $CLOUD ]; then
    CLOUD="metacloud"
fi

################# MAIN

/puppet/jenkins/bin/$CLOUD.init login
VMLIST=$(/puppet/jenkins/bin/$CLOUD.init list | grep "RC-" |awk '{print $4}')

# ZALOZENI TESTU
VMCOUNT=0
for all in $VMLIST; do
	echo "INFO: client $all config"
	VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh "(cat /etc/rsyslog.d/meta-remote.conf)" | awk -v VMNAME=$all '//{ print VMNAME,$0}'
	VMCOUNT=$(($VMCOUNT+1))
done

#nastaveni kratkeho KA
/puppet/jenkins/bin/$CLOUD.init sshs 'echo "60" > /proc/sys/net/ipv4/tcp_keepalive_time;echo "1" > /proc/sys/net/ipv4/tcp_keepalive_intvl;echo "1"> /proc/sys/net/ipv4/tcp_keepalive_probes'

#reconnect all clients
/puppet/jenkins/bin/$CLOUD.init sshs 'service rsyslog stop'
/puppet/jenkins/bin/$CLOUD.init sshs 'service rsyslog start'
for all in $VMLIST; do
	echo "INFO: client $all restart"
	VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh "service rsyslog restart"
done
sleep 10
CONNS=$(/puppet/jenkins/bin/$CLOUD.init sshs 'netstat -nlpa | grep rsyslog | grep ESTA | awk "{print \$4}" | grep "51[456]" | wc -l' | head -n1)
if [ $CONNS -ne $VMCOUNT ]; then
	rreturn 1 "$0 missing clients on startup"
fi




#failing sockets
/puppet/jenkins/bin/$CLOUD.init sshs 'iptables -I INPUT -m multiport -p tcp --dport 514,515,516 -j DROP'

for all in $VMLIST; do
	echo "INFO: failing client $all"
	VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh "killall -9 rsyslogd"
done

sleep 120

CONNS=$(/puppet/jenkins/bin/$CLOUD.init sshs 'netstat -nlpa | grep rsyslog | grep ESTA | awk "{print \$4}" | grep "51[456]" | wc -l' | head -n1)

/puppet/jenkins/bin/$CLOUD.init sshs 'iptables -D INPUT -m multiport -p tcp --dport 514,515,516 -j DROP'
/puppet/jenkins/bin/$CLOUD.init sshs 'echo "7200" > /proc/sys/net/ipv4/tcp_keepalive_time;echo "75" > /proc/sys/net/ipv4/tcp_keepalive_intvl;echo "9" > /proc/sys/net/ipv4/tcp_keepalive_probes'

if [ $CONNS -ne 0 ]; then
	rreturn 1 "$0 dead clients detected"
else
	rreturn 0 "$0"
fi

