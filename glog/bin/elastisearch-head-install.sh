#!/bin/sh
set -e

echo "INFO: install elasticsearch-head"
cd /opt
git clone git://github.com/mobz/elasticsearch-head.git
cd elasticsearch-head
npm install

