#!/bin/sh
# script will test remote host/hostname rekeying over ssh
# usage: sh krb/tests/rekey_remote_heimdal.sh fqdn

. /puppet/metalib/bin/lib.sh


BASE="$(readlink -f $(dirname $(readlink -f $0))/../..)"
REMOTE=$1
checkzero ${REMOTE}

KEYTAB="/etc/krb5.keytab"
PRINCIPAL="host/${REMOTE}"

ADMINKEYTAB="/tmp/rekey_remote.keytab"
export KRB5CCNAME="/tmp/rekey_remote.ccache"
kadmin.heimdal --local ext_keytab --keytab=${ADMINKEYTAB} testroot@RSYSLOG3
kinit --keytab=${ADMINKEYTAB} testroot@RSYSLOG3



echo "========== INFO: prologue"
kdestroy --credential=${PRINCIPAL}
ssh ${REMOTE} "/bin/true"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 prologue ssh"
fi
echo "INFO: keytab list"
klist -v



echo "========== INFO: rekey begin"
${BASE}/krb/bin/rekey.py --keytab ssh://${REMOTE}${KEYTAB} --principal ${PRINCIPAL} --puppetstorage ssh://${REMOTE}/dev/shm/puppetstoragetest --debug
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rekey"
fi
echo "========== INFO: rekey end"




echo "========== INFO: epilogue"
kdestroy --credential=${PRINCIPAL}
ssh ${REMOTE} "/bin/true"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 epilogue ssh"
fi
echo "INFO: keytab list"
klist -v


unset KRB5CCNAME
rm ${ADMINKEYTAB}

rreturn 0 "$0"
