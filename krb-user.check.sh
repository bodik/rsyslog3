#!/bin/sh

test -f /etc/krb5.keytab 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: CHECK KRB-USER  ======================="
        pa.sh -v --noop --show_diff -e 'include krb::user'
fi
