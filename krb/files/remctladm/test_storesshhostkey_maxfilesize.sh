#!/bin/sh

. /puppet/metalib/bin/lib.sh

TESTFILE="/tmp/test_remctladm_maxfilesize"
MIN=0
MAX=1000000

while true; do

	TRY=$(( $MIN + (($MAX - $MIN) / 2) ))
	echo "DEBUG: attempt to transfer $TRY bytes"

	dd if=/dev/zero of=${TESTFILE} bs=$TRY count=1 1>/dev/null 2>/dev/null
	remctladm storesshhostkey --host $(facter fqdn) --filename ${TESTFILE} 1>/dev/null 2>/dev/null

	if [ $? -eq 0 ]; then
		MIN=$TRY
	else
		MAX=$TRY
	fi

	# we must count some epsilon due to integer arithmetics
	if [ $(($MAX - $MIN)) -lt 3 ]; then 
		break
	fi
done

rm -f ${TESTFILE} /var/ssh-key-storage/$(facter fqdn)/$(basename $TESTFILE)
rreturn 0 "maxfile size found $MIN"
