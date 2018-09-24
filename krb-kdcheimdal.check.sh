#!/bin/sh

dpkg -l | grep heimdal-kdc 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: CHECK KRB-KDCHEIMDAL  ======================="
        pa.sh -v --noop --show_diff -e 'include krb::kdcheimdal'
fi
