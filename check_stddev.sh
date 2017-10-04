#!/bin/sh 

for all in $(find . -maxdepth 2 -type f -name "*.check.sh"); do
	sh $all
done

pa.sh -v --noop --show_diff -e "include metalib::puppet_cleanup"
