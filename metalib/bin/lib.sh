#!/bin/sh

rreturn() {
	RET=$1
	MSG=$2
	if [ $RET -eq 0 ]; then
		echo "RESULT: OK $MSG"
		exit 0
	else
		echo "RESULT: FAILED $MSG"
		exit 1
	fi

	echo "RESULT: FAILED THIS SHOULD NOT HAPPEN $0 $@"
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

