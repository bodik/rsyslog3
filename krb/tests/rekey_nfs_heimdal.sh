#!/bin/sh
# script will test remote nfs/hostname principal rekeying on testbed mount /nfsroot, see krb::nfs* classes
# usage: sh krb/tests/rekey_nfs_heimdal.sh fqdn

. /puppet/metalib/bin/lib.sh


BASE="$(readlink -f $(dirname $(readlink -f $0))/../..)"
REMOTE=$1
checkzero ${REMOTE}

KEYTAB="/etc/krb5.keytab"
PRINCIPAL="nfs/${REMOTE}"

ADMINKEYTAB="/tmp/rekey_remote.keytab"
export KRB5CCNAME="/tmp/rekey_remote.ccache"
kadmin.heimdal --local ext_keytab --keytab=${ADMINKEYTAB} testroot@RSYSLOG3
kinit --keytab=${ADMINKEYTAB} testroot@RSYSLOG3



echo "========== INFO: prologue"
ssh ${REMOTE} '
	pa.sh -e "
		class {\"krb::user\": impl => \"heimdal\"}
		augeas {\"ticket_lifetime\": context => \"/files/etc/krb5.conf/libdefaults\", changes => [\"set ticket_lifetime 1m\"]}
	"
	umount /nfsroot; systemctl restart rpc-gssd; mount /nfsroot
'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 prologue mount with short ticket_lifetime"
fi
echo "WARN: >>> check kvno and service ticket lifetime"
ssh ${REMOTE} 'KRB5CCNAME=/tmp/krb5ccmachine_RSYSLOG3 klist -v' | egrep '(Credentials cache:|Server:|Client:|Ticket etype:|Auth time:|End time:)' | xargs -d'\n' printf "\t%s\n"
echo "WARN: >>> check kvno and service ticket lifetime"



echo "========== INFO: rekey client begin"
${BASE}/krb/bin/rekey.py --keytab ssh://${REMOTE}${KEYTAB} --principal ${PRINCIPAL} --puppetstorage ssh://${REMOTE}/dev/shm/puppetstoragetest --debug
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rekey client"
fi
echo "========== INFO: rekey client end"

echo "INFO: waiting for cache credentials to expire"
sleep 70
ssh ${REMOTE} 'ls /nfsroot 1>/dev/null'
echo "WARN: >>> check kvno and service ticket lifetime"
ssh ${REMOTE} 'KRB5CCNAME=/tmp/krb5ccmachine_RSYSLOG3 klist -v' | egrep '(Credentials cache:|Server:|Client:|Ticket etype:|Auth time:|End time:)' | xargs -d'\n' printf "\t%s\n"
echo "WARN: >>> check kvno and service ticket lifetime"



echo "========== INFO: rekey server begin"
${BASE}/krb/bin/rekey.py --keytab /etc/krb5.keytab --principal "nfs/$(hostname -f)" --debug
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rekey server"
fi
echo "========== INFO: rekey server end"

echo "INFO: waiting for cache credentials to expire"
sleep 70
ssh ${REMOTE} 'ls /nfsroot 1>/dev/null'
echo "WARN: >>> check kvno and service ticket lifetime"
ssh ${REMOTE} 'KRB5CCNAME=/tmp/krb5ccmachine_RSYSLOG3 klist -v' | egrep '(Credentials cache:|Server:|Client:|Ticket etype:|Auth time:|End time:)' | xargs -d'\n' printf "\t%s\n"
echo "WARN: >>> check kvno and service ticket lifetime"



unset KRB5CCNAME
rm ${ADMINKEYTAB}

rreturn 0 "$0"
