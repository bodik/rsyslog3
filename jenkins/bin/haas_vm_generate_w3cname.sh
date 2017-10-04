#!/bin/sh
echo "cz.cesnet.haas.$(facter hostname | sed 's/-//g')"
