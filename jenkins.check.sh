#!/bin/sh

if [ -f /etc/default/jenkins ]; then
        echo "INFO: CHECK JENKINS ===================="
	pa.sh -v --noop --show_diff -e "include metalib::base"
	pa.sh -v --noop --show_diff -e "include jenkins"
fi
