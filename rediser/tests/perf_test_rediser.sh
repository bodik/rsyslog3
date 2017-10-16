#!/bin/sh

. /puppet/metalib/bin/lib.sh

SELFDIR=$(dirname $(readlink -f $0))
TESTID="ti$(date +%s)"
LEN=11

usage() { echo "Usage: $0 [-c <TESTLEN>]" 1>&2; exit 1; }
while getopts "c:n:" o; do
    case "${o}" in
        c) LEN=${OPTARG} ;;
        *) usage ;;
    esac
done
shift "$((OPTIND-1))"



handler() {
	kill -9 $PID_READER $(pgrep -f "${SELFDIR}/perf_rediser_writer.py")

} 
trap handler INT



echo "INFO: test precheck"
/usr/lib/nagios/plugins/check_procs --argument-array="${SELFDIR}/perf_redis_reader.py" -c 0:0 || rreturn 1 "$0 perf_redis_reader.rb check_procs already running"
/usr/lib/nagios/plugins/check_procs --argument-array="${SELFDIR}/perf_rediser_writer.py" -c 0:0 || rreturn 1 "$0 perf_rediser_writer.rb check_procs already running"

QUEUELEN="$(/puppet/rediser/bin/redis.sh llen test)"
if [ $QUEUELEN -ne 0 ]; then
	rreturn 1 "$0 queue not empty"
fi




echo "INFO: test start"
TIME_START=$(date +%s)

#run reader
${SELFDIR}/perf_redis_reader.py --report 5 &
PID_READER=$!

${SELFDIR}/perf_rediser_writer.py --batch $LEN --id $TESTID --report 5

wait $PID_READER

TIME_STOP=$(date +%s)
