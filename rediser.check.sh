#!/bin/sh

test -f /opt/rediser/rediser.conf 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: CHECK REDISER ======================="
	pa.sh -v --noop --show_diff -e "include rediser"
fi
