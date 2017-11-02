#!/bin/sh

. /puppet/metalib/bin/lib.sh

KEYTAB="/tmp/test_remctladm_createkeytab_$$"
for service in ftp pbs nfs; do
	kadmin.local delprinc $service/$(facter fqdn) 1>/dev/null 2>/dev/null
done

# create
kinit -k -t /etc/krb5.keytab host/$(facter fqdn)
remctladm createkeytab --host $(facter fqdn) --services host ftp pbs nfs --outfile ${KEYTAB}
if [ $? -ne 0 ]; then
	rreturn 1 "remctladm failed"
fi

# test
for service in host ftp pbs nfs; do
	kinit -k -t ${KEYTAB} ${service}/$(facter fqdn) || rreturn 1 "$0 kinit $service failed"
done


rm -f ${KEYTAB}
rreturn 0 "$0"
