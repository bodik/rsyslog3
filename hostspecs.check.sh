#!/bin/sh 

if [ -e /puppet/hostspecs/host_$(facter fqdn).pp ]; then
        echo "INFO: CHECK HOSTSPEC ======================="
        pa.sh -v --noop --show_diff /puppet/hostspecs/host_$(facter fqdn).pp
fi


