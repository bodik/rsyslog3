#!/bin/sh

find /etc/rsyslog.d/ -name "meta-remote.conf" | grep meta 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: CHECK RSYSLOG-CLIENT ======================="
        pa.sh -v --noop --show_diff -e 'include rsyslog::client'
fi
