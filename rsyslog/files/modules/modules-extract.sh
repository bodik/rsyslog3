#!/bin/sh

BINDIR=$(dirname $0)

find . -type f -name "syslog*7z" -exec sh $BINDIR/modules-grep-7z.sh {} \;  
find . -type f -name "syslog*gz" -exec sh $BINDIR/modules-grep-gz.sh {} \;  

