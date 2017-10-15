#!/bin/sh

. /puppet/metalib/bin/lib.sh

test -n "$1" || rreturn 1 "$0 missing forward_type"

metacloud.init all 'RC-' "pa.sh -e 'class { \"rsyslog::client\": forward_type=>\"$1\"}'"
