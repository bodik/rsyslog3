#!bin/sh

elasticdump \
	--input=http://127.0.0.1:39200/.kibana \
	--output=\$ \
	--type=data \
	>/puppet/glog/files/kibana-data.json

