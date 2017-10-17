#!/bin/sh

if [ -e /puppet/hostspecs/host_$(facter fqdn).pp ]; then
        pa.sh -v /puppet/hostspecs/host_$(facter fqdn).pp
else
	echo "INFO: no hostspecs::$(facter fqdn)"
fi
