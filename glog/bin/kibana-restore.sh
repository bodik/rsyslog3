#!bin/sh

elasticdump \
	--input=/puppet/glog/files/kibana-data.json \
	--output=http://127.0.0.1:39200/.kibana \
	--type=data

