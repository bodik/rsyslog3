#!/bin/sh

dpkg -l | grep apache2 1>/dev/null 2>/dev/null && test ! -d /home/apache/ 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: CHECK LAMP ======================="
	pa.sh -v --noop --show_diff -e "include lamp::apache2"
fi
