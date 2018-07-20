#!/bin/sh

. /puppet/metalib/bin/lib.sh


BASE="$(readlink -f $(dirname $(readlink -f $0))/../..)"
REMOTE=$1
KEYTAB=$2
PRINCIPAL=$3
checkzero ${REMOTE}
checkzero ${KEYTAB}
checkzero ${PRINCIPAL}


ADMINKEYTAB="/tmp/rekey_remote.keytab"
export KRB5CCNAME="/tmp/rekey_remove.ccache"
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
${BASE}/krb/bin/rekey_heimdal.py --keytab ssh://${REMOTE}${KEYTAB} --principal ${PRINCIPAL} --debug
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
