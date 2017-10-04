#!/bin/sh

find /puppet/ -name "vm_finalize.sh" -exec /bin/sh {} $@ \;

