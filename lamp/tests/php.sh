#!/bin/sh

. /puppet/metalib/bin/lib.sh


#php engine, tuning
TMPFILE=$(mktemp)
curl --silent --insecure --include "https://$(facter fqdn)/rsyslog3/test/binfo.php" > ${TMPFILE}
if [ $? -ne 0 ]; then
	rreturn 1 "$0 php test phpinfo"
fi
#links -force-html -dump ${TMPFILE}

grep 'PHP Version <.*7\.0' ${TMPFILE}
if [ $? -ne 0 ]; then
	rreturn 1 "$0 php engine not found"
fi

grep 'disable_functions.*exec.*passthru.*popen.*system.*shell_exec.*proc_open' ${TMPFILE} 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 php include path"
fi

rm -f ${TMPFILE}


#app engine tests
curl --silent --insecure --include "https://$(facter fqdn)/rsyslog3/test/test_mysql_functions.php" | grep 'mysql functions present'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 php test_mysql_functions.php"
fi


rreturn 0 "$0"

