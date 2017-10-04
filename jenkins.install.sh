#!/bin/sh

/puppet/metalib/bin/pa.sh -v -e "include metalib::base"
pa.sh -v -e "include jenkins"
