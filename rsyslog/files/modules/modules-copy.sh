#!/bin/sh

for all in $(find . -name "*modules"); do 
	mkdir -p ${HOME}/logs-modules/$(dirname $all)
	cp $all ${HOME}/logs-modules/$all
done

