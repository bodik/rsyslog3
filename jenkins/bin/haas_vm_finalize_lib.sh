#!/bin/sh


rreturn() { echo "$2"; exit $1; }

usage() { echo "Usage: $0 -w <WARDEN_SERVER_URL> -n <CLIENT_NAME> -t <TOKEN>" 1>&2; exit 1; }
parse_args() {
	AUTOTEST=0
	while getopts "w:n:t:a" o; do
		case "${o}" in
	        	w) WARDEN_SERVER_URL=${OPTARG} ;;
			n) CLIENT_NAME=${OPTARG} ;;
			t) TOKEN=${OPTARG} ;;
			a) AUTOTEST=1 ;;
			*) usage ;;
		esac
	done
	shift "$(($OPTIND-1))"

	test -n "$WARDEN_SERVER_URL" || rreturn 1 "ERROR: missing WARDEN_SERVER_URL"
	test -n "$CLIENT_NAME" || rreturn 1 "ERROR: missing CLIENT_NAME"
	test -n "$TOKEN" || rreturn 1 "ERROR: missing TOKEN"
}

