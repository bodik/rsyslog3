#!/bin/sh

set -e

for all in $(find $(dirname $(readlink -f $0)) -type f -name 'test_*'); do 
	sh $all
done
