#!/bin/sh

test -f /etc/krb5.keytab 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: CHECK KRB5-USER  ======================="
        pa.sh -v --noop --show_diff -e 'include krb5::user'
fi
