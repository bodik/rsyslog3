#!/bin/sh

rreturn() {
	RET=$1; shift

	if [ $RET -eq 0 ]; then
		echo "RESULT: OK $@"
		exit 0
	fi

	echo "RESULT: FAILED $@"
	exit 1
}

countdown() {
	TIMER=$1
	echo "INFO: begin countdown"
	while [ $TIMER -gt 0 ]; do
		if [ $(($TIMER % 30)) -eq 0 ]; then echo "DEBUG: countdown $TIMER"; fi
		TIMER=$(($TIMER-1))
	        sleep 1
	done
	echo "INFO: end countdown"
}

checkzero() {
        if [ -z "$1" ]; then
                echo "ERROR: some variable missing"
                exit 1
        fi
}
