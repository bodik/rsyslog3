#!/bin/sh

. /puppet/metalib/bin/lib.sh

TESTFILE_SRC="/var/ssh-key-storage/$(facter fqdn)/test_remctladm_getsshhostkey_$$"
TESTFILE_DST="/tmp/$(basename $TESTFILE_SRC)"
mkdir -p $(dirname ${TESTFILE_SRC})
dd if=/dev/urandom bs=100 count=1 2>/dev/null | sha256sum > ${TESTFILE_SRC}


# push
kinit -k -t /etc/krb5.keytab host/$(facter fqdn)
remctladm getsshhostkey --host $(facter fqdn) --filename $(basename ${TESTFILE_SRC}) --outfile ${TESTFILE_DST}
if [ $? -ne 0 ]; then
	rreturn 1 "remctladm failed"
fi


# test
diff -rua ${TESTFILE_SRC} ${TESTFILE_DST}
if [ $? -ne 0 ]; then
	rreturn 1 "retrieved file differs"
fi


rm -f ${TESTFILE_SRC} ${TESTFILE_DST}
rreturn 0 "$0"
