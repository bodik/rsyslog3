#!/bin/sh

. /puppet/metalib/bin/lib.sh


#redis server check
/usr/lib/nagios/plugins/check_procs --argument-array=redis-server -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 redis-server check_procs"
fi

redis-cli -p 16379 script load "return 1"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 redis-server version not sufficient"
fi

echo "rpush test_rediser.sh test_rediser.sh-$$" | redis-cli -p 16379 1>/dev/null
echo "lpop test_rediser.sh" | redis-cli -p 16379 | grep "test_rediser.sh-$$" 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 redis-server rpush/lpop failed"
fi


#rediser kontrolle
/usr/lib/nagios/plugins/check_procs --argument-array="/usr/sbin/rsyslogd -n -f /etc/rediser.conf" -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rediser check_procs"
fi

netstat -nlpa | grep "/rsyslogd " | grep LISTEN | grep :47800
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rediser listener"
fi


MSG="selftest $(date +%s)"
echo $MSG | nc -q0 localhost 47800
#redis-cli -p 16379 lpop test | grep "$MSG"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rediser failed"
fi


SERVICE=_rediser._tcp
avahi-browse -t $SERVICE --resolve -p | grep $(facter ipaddress)
if [ $? -ne 0 ]; then
	rreturn 1 "$0 _rediser._tcp not found"
fi


rreturn 0 "$0"
