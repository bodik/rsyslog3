#!/bin/sh

rreturn() { echo "$2"; exit $1; }

test -n "$1" || rreturn 1 "ERROR: missing DIR"
DIR="$1"

for all in $(find $DIR -type f ! -name "*7z"); do
        nice -n 15 7za a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on $all.7z $all
        if [ $? == 0 ]; then
		rm $all
        fi
done

