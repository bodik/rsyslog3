#!/bin/sh

set -e
. /puppet/metalib/bin/lib.sh

TESTID="ti$(date +%s)"
COUNT=11
DISRUPT="none"
CLOUD="metacloud"

usage() { echo "Usage: $0 [-t <TESTID>] [-c <COUNT>] [-d <DISRUPT>] [-f <CLOUD>]" 1>&2; exit 1; }
while getopts "t:c:d:f:" o; do
	case "${o}" in
        	t) TESTID=${OPTARG} ;;
        	c) COUNT=${OPTARG} ;;
        	d) DISRUPT=${OPTARG} ;;
        	f) CLOUD=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
CLOUDBIN="/puppet/jenkins/bin/${CLOUD}.init"






################# MAIN

echo "INFO: begin test setup"

NODES=$(${CLOUDBIN} list | grep "RC-" | awk '{print $4}' | grep -v "^$")

for all in $NODES; do
	VMNAME=$all ${CLOUDBIN} ssh "cd /puppet && sh bootstrap.install.sh 1>/dev/null 2>/dev/null" &
done
wait

NODESCOUNT=0
for all in $NODES; do
	echo "INFO: node $all config"
	VMNAME=$all ${CLOUDBIN} ssh "dpkg -l rsyslog | tail -n1; cat -n /etc/rsyslog.d/meta-remote.conf" 2>&1 | sed "s/^/$all /"
	NODESCOUNT=$(($NODESCOUNT+1))
done

echo "INFO: nodescount $NODESCOUNT"



echo "INFO: reconnecting all nodes"

${CLOUDBIN} sshs 'service rsyslog stop'
${CLOUDBIN} sshs 'service rsyslog start'
for all in $NODES; do
	echo "INFO: node $all rsyslog restart"
	VMNAME=$all ${CLOUDBIN} ssh "service rsyslog restart" &
done
wait
sleep 10

${CLOUDBIN} sshs 'netstat -nlpa | grep rsyslog | grep ESTA | grep ":51[456] "'
CONNS=$(${CLOUDBIN} sshs 'netstat -nlpa | grep rsyslog | grep ESTA | grep ":51[456] " | wc -l' | head -n1)
echo "INFO: connected nodes ${CONNS}"
if [ $CONNS -ne $NODESCOUNT ]; then
	rreturn 1 "$0 missing nodes on startup"
fi

echo "INFO: end test setup"






echo "INFO: begin test body"

for all in $NODES; do
	echo "INFO: node $all testi.sh init"
	VMNAME=$all ${CLOUDBIN} ssh "/puppet/rsyslog/test03/testi.sh -t ${TESTID} -c ${COUNT} </dev/null 1>/dev/null 2>/dev/null" &
done


# disrupts
WAITRECOVERY=60

###case $DISRUPT in
###
###
###	tcpkill)
###(
###sleep 10;
###TIMER=240
###echo "INFO: tcpkill begin $TIMER";
###/puppet/jenkins/bin/$CLOUD.init sshs "cd /puppet/rsyslog/test02;
###./tcpkill -i eth0 port 515 or port 514 or port 516 2>/dev/null &
###PPP=\$!; 
###sleep $TIMER;
###kill \$PPP;
###"
###echo "INFO: tcpkill end $TIMER";
###)
###WAITRECOVERY=230
###;;
###
###
###	restart)
###(
###sleep 10; 
###echo "INFO: restart begin";
###/puppet/jenkins/bin/$CLOUD.init sshs 'service rsyslog restart'
###echo "INFO: restart end";
###)
###WAITRECOVERY=230
###;;
###
###
###	killserver)
###(
###sleep 10; 
###echo "INFO: killserver begin";
###/puppet/jenkins/bin/$CLOUD.init sshs 'kill -9 `pidof rsyslogd`'
###/puppet/jenkins/bin/$CLOUD.init sshs 'service rsyslog restart'
###echo "INFO: killserver end";
###)
###WAITRECOVERY=230
###;;
###
###
###	ipdrop)
###(
###sleep 10;
###TIMER=240
###echo "INFO: ipdrop begin $TIMER";
###/puppet/jenkins/bin/$CLOUD.init sshs 'iptables -I INPUT -m multiport -p tcp --dport 514,515,516 -j DROP'
###sleep $TIMER;
###/puppet/jenkins/bin/$CLOUD.init sshs 'iptables -D INPUT -m multiport -p tcp --dport 514,515,516 -j DROP'
###echo "INFO: ipdrop end $TIMER";
###)
###WAITRECOVERY=230
###;;
###
###
###	manual)
###(
###sleep 10;
###TIMER=120
###echo "INFO: manual begin $TIMER";
###count $TIMER
###echo "INFO: manual end $TIMER";
###)
###WAITRECOVERY=230
###;;
###
###
###esac

echo "INFO: waiting for nodes to finish"
wait
echo "INFO: nodes finished"

echo "INFO: waiting to sync for $WAITRECOVERY secs"
count $WAITRECOVERY

echo "INFO: end test body"






echo "INFO: begin test result"

## test results
for all in $NODES; do
	NODEIP=$(VMNAME=$all ${CLOUDBIN} ssh 'facter ipaddress' | head -n1)
	${CLOUDBIN} sshs "/puppet/rsyslog/test03/result_client.py -n ${NODEIP} -t ${TESTID} -c ${COUNT} 1>>/tmp/test_results.${TESTID}.log 2>&1"
done
${CLOUDBIN} sshs "cat /tmp/test_results.${TESTID}.log"
${CLOUDBIN} sshs "/puppet/rsyslog/test03/result_test.py -t ${TESTID} -c ${COUNT} -n ${NODESCOUNT} -D ${DISRUPT} -l /tmp/test_results.${TESTID}.log --debug"
RET=$?

echo "INFO: end test result"

rreturn $RET "$0"
