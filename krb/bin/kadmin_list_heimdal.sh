#!/bin/sh
kadmin.heimdal --config=/etc/heimdal-kdc/kdc.conf --local list -s --column-info=principal,kvno,keytypes '*'
