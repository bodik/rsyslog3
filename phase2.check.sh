#!/bin/sh

/bin/true 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: CHECK PHASE2 ====================="
	/puppet/metalib/bin/pa.sh -v --noop --show_diff -e "include metalib::base"
	/puppet/metalib/bin/pa.sh -v --noop --show_diff -e "include iptables"
fi
