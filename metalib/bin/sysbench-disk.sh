#!/bin/sh

BENCHDIR="/scratch/sysbench-fileio-benchmark.$$"
TESTSIZE="50G"

mkdir -p "${BENCHDIR}"
cd "${BENCHDIR}" || exit 1

for testtype in rndrd rndwr rndrw; do
	echo "INFO: sysbench ${testtype} ${TESTSIZE}"
	for all in $(seq 1 5); do
		sysbench --num-threads=8 --test=fileio --file-total-size=${TESTSIZE} --file-test-mode=${testtype} prepare 1>/dev/null
		sysbench --num-threads=8 --test=fileio --file-total-size=${TESTSIZE} --file-test-mode=${testtype} run | grep 'Total transferred'
		sysbench --num-threads=8 --test=fileio --file-total-size=${TESTSIZE} --file-test-mode=${testtype} cleanup 1>/dev/null
	done
done
rm -rf "${BENCHDIR}"

