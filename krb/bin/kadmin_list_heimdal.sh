#!/bin/sh
kadmin.heimdal --local list -s --column-info=principal,kvno,keytypes '*'
