#!/bin/sh

set -e
. /puppet/metalib/bin/lib.sh

TESTID="ti$(date +%s)"
COUNT=11
DISRUPT="none"
CLOUD="metacloud"

rreturn() { echo "$2"; exit $1; }
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

VMLIST=$(${CLOUDBIN} list | grep "RS-" | awk '{print $4}' | grep -v "^$")

# gather test info
VMCOUNT=0
for all in $VMLIST; do
	echo "INFO: client $all config"
	VMNAME=$all ${CLOUDBIN} ssh "dpkg -l rsyslog; cat /etc/rsyslog.d/meta-remote.conf" 2>&1 | sed "s/^/$all /"
	VMCOUNT=$(($VMCOUNT+1))
done
echo "INFO: VMCOUNT $VMCOUNT"
echo "INFO: VMLIST $VMLIST"


exit 0

#reconnect all clients
${CLOUDBIN} sshs 'service rsyslog stop'
${CLOUDBIN} sshs 'service rsyslog start'
for all in $VMLIST; do
	echo "INFO: client $all restart"
	VMNAME=$all ${CLOUDBIN} ssh "service rsyslog restart"
done
sleep 10
CONNS=$(${CLOUDBIN} sshs 'netstat -nlpa | grep rsyslog | grep ESTA | awk "{print \$4}" | grep "51[456]" | wc -l' | head -n1)
if [ $CONNS -ne $VMCOUNT ]; then
	rreturn 1 "$0 missing clients on startup"
fi

exit 0



for all in $VMLIST; do
	echo "INFO: client $all testi.sh init"
	VMNAME=$all ${CLOUDBIN} ssh "(sh /puppet/rsyslog/test03/testi.sh -t ${TESTID} -c ${COUNT} </dev/null 1>/dev/null 2>/dev/null)" &
done

###
###
#### VYNUCOVANI CHYB
###WAITRECOVERY=60
###
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

echo "INFO: waiting for clients to finish"
wait
echo "INFO: test finished"






# CEKANI NA DOTECENI VYSLEDKU
WAITRECOVERY=60
echo "INFO: waiting to sync for $WAITRECOVERY secs"
count $WAITRECOVERY





# VYHODNOCENI VYSLEDKU
for all in $VMLIST; do
	CLIENT=$( VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh 'facter ipaddress' |grep -v "RESULT")
	/puppet/jenkins/bin/$CLOUD.init sshs "sh /puppet/rsyslog/test02/results_client.sh $LEN $TESTID $CLIENT" | grep "RESULT TEST NODE:" | tee -a /tmp/test_results.$TESTID.log
done
echo =============

awk -v LEN=$LEN -v VMCOUNT=$VMCOUNT -v TESTID=$TESTID -v DISRUPT=$DISRUPT ' 
BEGIN {
	DELIVERED=0;
	DELIVEREDUNIQ=0;
	TOTALLEN=LEN*VMCOUNT;
}
//{
	DELIVERED = DELIVERED + $10;
	DELIVEREDUNIQ = DELIVEREDUNIQ + $14;
}
END {
	PERC=DELIVERED/(TOTALLEN/100);
	PERCUNIQ=DELIVEREDUNIQ/(TOTALLEN/100);
	if(PERCUNIQ >= 99.0 && PERCUNIQ <= 100 ) {
		RES="OK";
		RET=0;
	} else {
		RES="FAILED";
		RET=1;
	}
	print "RESULT TEST FINAL:",RES,TESTID,"disrupt",DISRUPT,"totallen",TOTALLEN,"deliv",DELIVERED,"rate",PERC"%","delivuniq",DELIVEREDUNIQ,"rateuniq",PERCUNIQ"%";
	exit RET
}' /tmp/test_results.$TESTID.log
RET=$?

rm /tmp/test_results.$TESTID.log

rreturn $RET "$0"

