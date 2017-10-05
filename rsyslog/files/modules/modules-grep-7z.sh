#!/bin/sh

BEGIN=`date +%s`
echo "BEGIN: $0 $1"

7z -so x $1 | grep "modules:" 1>$1.modules 2>/dev/null

END=`date +%s`
TIME=$(($END-$BEGIN))
echo "END: $0 $1 in ${TIME}s"

