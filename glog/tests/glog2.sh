#!/bin/sh

. /puppet/metalib/bin/lib.sh




/usr/lib/nagios/plugins/check_procs --argument-array=org.elasticsearch.bootstrap.Elasticsearch -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 org.elasticsearch.bootstrap.Elasticsearch check_procs"
fi

ESD_AGE=$(ps h -o etimes $(pgrep -f org.elasticsearch.bootstrap.Elasticsearch))
if [ $ESD_AGE -lt 60 ] ; then
	echo "INFO: esd warming up"
	sleep 120
fi

netstat -nlpa | grep " $(pgrep -f org.elasticsearch.bootstrap.Elasticsearch)/java" | grep LISTEN | grep ":39200"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 esd http listener"
fi

wget "http://127.0.0.1:39200" -q -O /dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 esd http interface"
fi

netstat -nlpa | grep " $(pgrep -f grunt)/grunt" | grep LISTEN | grep ":39100"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 elasticsearch-head http listener"
fi




/usr/lib/nagios/plugins/check_procs --argument-array=logstash/runner.rb -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 logstash/runner.rb check_procs"
fi

LOGSTASH_AGE=$(ps h -o etimes $(pgrep -f logstash/runner.rb))
if [ $LOGSTASH_AGE -lt 60 ] ; then
	echo "INFO: logstash warming up"
	sleep 120
fi

netstat -nlpa | grep " $(pgrep -f logstash/runner.rb)/java" | egrep "udp.*:::39994"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 logstash/runner.rb not listening for gcm logs"
fi




for all in "http://$(facter fqdn)" "http://$(facter ipaddress)" "http://127.0.0.1" ; do
	curl --insecure --silent --include "${all}/head" | head -1 | grep '^HTTP/1.1 404 Not Found'
	if [ $? -ne 0 ]; then
		rreturn 1 "$0 apache2 ${all} http esd head uri"
	fi

	curl --insecure --silent --include "${all}/esd" | head -1 | grep '^HTTP/1.1 404 Not Found'
	if [ $? -ne 0 ]; then
		rreturn 1 "$0 apache2 ${all} http esd uri"
	fi
done

curl --insecure --silent --include "https://$(facter fqdn)/esd" | grep 'You Know, for Search'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 https esd proxy check"
fi

curl --insecure --silent --include "https://$(facter fqdn)/head/" | grep '<title>elasticsearch-head</title>'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 https plugin head check"
fi

curl --insecure --silent --include "https://$(facter fqdn)/esd/_template?pretty=true" | grep 'logstash'
if [ $? -ne 0 ]; then
	rreturn 1 "$0 esd missing mapping"
fi





/usr/lib/nagios/plugins/check_procs --argument-array=/usr/share/kibana/bin/../node/bin/node -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 kibana check_procs"
fi

for all in "http://$(facter fqdn)" "http://$(facter ipaddress)" "http://127.0.0.1" ; do
	curl --insecure --silent --include "${all}/kibana" | head -1 | grep '^HTTP/1.1 404 Not Found'
	if [ $? -ne 0 ]; then
		rreturn 1 "$0 apache2 http ${all} kibana maskforbidden check"
	fi
done

I=6
while(true); do
	curl --insecure --silent --include "https://$(facter fqdn)/kibana/" | head -1 | grep '^HTTP/1.1 200 OK'
	if [ $? -eq 0 ]; then
		#ok
		break
	else
		if [ $I -gt 0 ]; then
			echo "INFO: sleeping for kibana to warmup"
			sleep 30
			I=$(($I-1))
		else
			rreturn 1 "$0 apache2 https kibana check"
		fi
	fi
done





RANDOM=$(/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print $1}')
echo "{\"message\": \"autotest\", \"x\":\"${RANDOM}\"}" | nc -q0 -u 127.0.0.1 39994

I=60
while(true); do
	curl -XPOST --insecure --silent --include "https://$(facter fqdn)/esd/_search?pretty" -d \
	'{"query": { "query_string": { "query": "message:\"autotest\" AND x:\"'${RANDOM}'\"" } } }' | grep ${RANDOM}
	if [ $? -eq 0 ]; then
		#ok
		break
	else
		if [ $I -gt 0 ]; then
			echo "INFO: sleeping for index"
			sleep 1
			I=$(($I-1))
		else
			rreturn 1 "$0 misc udp input indexing"
		fi
	fi
done



elasticdump --help | head -n1 | grep "elasticdump: Import and export tools for elasticsearch"
if [ $? -ne 0 ]; then
        rreturn 1 "$0 elasticdump not installed"
fi



rreturn 0 "$0"

