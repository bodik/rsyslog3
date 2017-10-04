#!/bin/sh
set -e

sh /puppet/lamp/tests/apache2.sh
sh /puppet/lamp/tests/php.sh

