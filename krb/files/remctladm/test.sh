#!/bin/sh

find $(dirname $(readlink -f $0)) -type f -name 'test_*' -exec /bin/sh {} \;
