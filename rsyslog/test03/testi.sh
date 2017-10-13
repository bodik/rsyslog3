#!/bin/bash

set -e
TESTID="ti$(date +%s)"
COUNT=11

rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 [-t <TESTID>] [-c <COUNT>]" 1>&2; exit 1; }
while getopts "t:c:" o; do
	case "${o}" in
        	t) TESTID=${OPTARG} ;;
        	c) COUNT=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"

I=0
while [ $I -lt $COUNT ]; do
        logger -t logger "$TESTID tmsg$I"
	#/rsyslog2/usleep 500
	I=$(($I+1))
done

