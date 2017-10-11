#!/bin/sh

SERVER="esb.metacentrum.cz"
PORT=47801

rreturn() { echo "$2"; exit $1; }
usage() { echo "Usage: $0 -d <DIR> [-s <SERVER>] [-p <PORT>]" 1>&2; exit 1; }
while getopts "d:s:p:" o; do
	case "${o}" in
        	d) DIR=${OPTARG} ;;
        	s) SERVER=${OPTARG} ;;
		p) PORT=${OPTARG} ;;
		*) usage ;;
	esac
done
shift "$(($OPTIND-1))"
test -n "$DIR" || rreturn 1 "ERROR: missing DIR"


echo -n "INFO: du "
du -sh $DIR
BEGIN=`date +%s`
echo "BEGIN: $DIR"

(find $DIR -type f ! -name "*7z" -exec cat {} \; ; find $DIR -type f -name "*7z" -exec 7z -so x {} 2>/dev/null \;) | grep "modules:" | pv | nc -q3 $SERVER $PORT

END=`date +%s`
TIME=$(($END-$BEGIN))
echo "END: $DIR in ${TIME}s"
