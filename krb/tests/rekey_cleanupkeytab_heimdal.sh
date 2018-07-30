#!/bin/sh
# script will test cleanup functionality
# usage: sh krb/tests/rekey_service_heimdal.sh

. /puppet/metalib/bin/lib.sh


BASE="$(readlink -f $(dirname $(readlink -f $0))/../..)"
KEYTAB="/tmp/rekey_service.keytab"
PRINCIPAL="hostx/$(hostname -f)@RSYSLOG3"



echo "========== INFO: cleanup"
kadmin.heimdal --local del ${PRINCIPAL}
rm -f ${KEYTAB} ${KEYTAB}.new ${KEYTAB}.rekeybackup*



echo "========== INFO: create key and garbage key"
kadmin.heimdal --local ank --use-defaults --random-key ${PRINCIPAL}
kadmin.heimdal --local ext_keytab --keytab=${KEYTAB} ${PRINCIPAL}
ktutil --keytab=${KEYTAB} add --random --principal=${PRINCIPAL} --kvno=666 --enctype=des3-cbc-sha1
echo "INFO: keytab list"
ktutil --keytab=${KEYTAB} list



echo "========== INFO: rekey begin"
${BASE}/krb/bin/rekey.py --keytab ${KEYTAB} --principal ${PRINCIPAL} --action cleanupkeytab --debug
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rekey"
fi
echo "========== INFO: rekey end"



echo "INFO: check garbage removal"
ktutil --keytab=${KEYTAB} list | grep "666.*des3-cbc-sha1.*${PRINCIPAL}"
if [ $? -ne 1 ]; then
	rreturn 1 "$0 garbage key not removed"
fi



echo "========== INFO: cleanup"
rm -f ${KEYTAB} ${KEYTAB}.rekeybackup*

rreturn 0 "$0"
