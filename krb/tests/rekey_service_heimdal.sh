#!/bin/sh
# script will test basic rekeying functionality on local keytab using a test principal hostx/self-fqdn
# usage: sh krb/tests/rekey_service_heimdal.sh

. /puppet/metalib/bin/lib.sh


BASE="$(readlink -f $(dirname $(readlink -f $0))/../..)"
KEYTAB="/tmp/rekey_service.keytab"
PRINCIPAL="hostx/$(hostname -f)"
export KRB5CCNAME="/tmp/rekey_service.ccache"



echo "========== INFO: cleanup"
kadmin.heimdal --local del ${PRINCIPAL}
rm -f ${KEYTAB} ${KEYTAB}.new ${KEYTAB}.rekeybackup*
kdestroy






echo "========== INFO: create old key"
KRB5_CONFIG=/etc/heimdal-kdc/kadmin-weakcrypto.conf kadmin.heimdal --local ank --use-defaults --random-key ${PRINCIPAL}
kadmin.heimdal --local ext_keytab --keytab=${KEYTAB} ${PRINCIPAL}
echo "INFO: weak crypto principal list"
kadmin.heimdal --local get ${PRINCIPAL}
echo "INFO: weak keytab list"
ktutil --keytab=${KEYTAB} list






echo "========== INFO: test old key"
gss-server -port 41000 -once -keytab ${KEYTAB} hostx &
sleep 1

kinit --keytab=${KEYTAB} ${PRINCIPAL}
gss-client -q -port 41000 $(hostname -f) hostx messagex
if [ $? -ne 0 ]; then
	pgrep gss-server | xargs --no-run-if-empty kill -TERM
	rreturn 1 "$0 gss-client old key"
fi
# there should be weak crypto service ticket in the cache
echo "INFO: weak crypto ccache list"
klist -v






echo "========== INFO: rekey begin"
${BASE}/krb/bin/rekey.py --keytab ${KEYTAB} --principal ${PRINCIPAL} --debug
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rekey"
fi
echo "========== INFO: rekey end"






echo "========== INFO: test transition old key"
gss-server -port 41000 -once -keytab ${KEYTAB} hostx &
sleep 1

gss-client -q -port 41000 $(hostname -f) hostx messagex
if [ $? -ne 0 ]; then
	pgrep gss-server | xargs --no-run-if-empty kill -TERM
	rreturn 1 "$0 gss-client old key transition"
fi
# there should be the same weak crypto service ticket in the cache
echo "INFO: weak crypto transition ccache"
klist -v






echo "========== INFO: test transition new key"
kadmin.heimdal --local ext_keytab --keytab=${KEYTAB}.new ${PRINCIPAL}
kdestroy
kinit --keytab=${KEYTAB}.new ${PRINCIPAL}

gss-server -port 41000 -once -keytab ${KEYTAB} hostx &
sleep 1

gss-client -q -port 41000 $(hostname -f) hostx messagex
if [ $? -ne 0 ]; then
	pgrep gss-server | xargs --no-run-if-empty kill -TERM
	rreturn 1 "$0 gss-client new key"
fi
# three should be strong crypto ticket in the cache
echo "INFO: strong crypto ccache"
klist -v




echo "========== INFO: cleanup"
rm -f ${KEYTAB} ${KEYTAB}.new ${KEYTAB}.rekeybackup* ${KRB5CCNAME}
unset KRB5CCNAME

rreturn 0 "$0"
