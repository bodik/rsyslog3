#!/bin/sh

dpkg -l krb5-kdc 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: CHECK KRB-KDCMIT  ======================="
        pa.sh -v --noop --show_diff -e 'include krb::kdcmit'
fi
