#!/bin/sh

redis-cli --raw -p 16379 $@
exit $?
