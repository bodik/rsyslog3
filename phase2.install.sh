#!/bin/sh

sh /puppet/metalib/bin/pa.sh -e "include metalib::base"
sh /puppet/metalib/bin/pa.sh -e "include iptables"
