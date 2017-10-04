#!/bin/sh

. /puppet/metalib/bin/lib.sh

dpkg -l firmware-linux-nonfree 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apt/dpkg non-free not installed"
fi

/usr/lib/nagios/plugins/check_procs --argument-array=/usr/bin/fail2ban-server -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 fail2ban check_procs"
fi
# https://mantisgit.gc-system.cz:22334/view.php?id=1961
# pro ted ponechame post instalacni refreshe a mizeni fail2ban pravidel stranou
#iptables-save | grep "\-j f2b-ssh"
#if [ $? -ne 0 ]; then
#	rreturn 1 "$0 fail2ban iptables rules not active"
#fi


/usr/lib/nagios/plugins/check_procs --argument-array=/usr/lib/postfix/sbin/master -c 1:1
if [ $? -ne 0 ]; then
        rreturn 1 "$0 postfix check_procs"
fi
mailq 1>/dev/null
if [ $? -ne 0 ]; then
        rreturn 1 "$0 postfix mailq"
fi



sh /puppet/iptables/tests/iptables.sh
if [ $? -ne 0 ]; then
	rreturn 1 "$0 iptables differs"
fi


rreturn 0 "$0"
