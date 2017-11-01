#!/bin/sh

. /puppet/metalib/bin/lib.sh

test -f /etc/krb5.keytab || rreturn 1 "$0 missing keytab"

kinit -k || rreturn 1 "$0 kinit by keytab error"

rreturn 0 "$0"
