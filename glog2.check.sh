#!/bin/sh

dpkg -l | grep elasticsearch | grep 5.4 >/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: CHECK GLOG2CHECK ================="
	pa.sh -v --noop --show_diff -e "include glog::glog2"
fi
