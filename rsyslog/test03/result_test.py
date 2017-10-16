#!/usr/bin/python

import argparse
import json
import logging
import re
import socket
import sys

logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, format='%(levelname)s %(message)s')

if __name__ == "__main__":

	parser = argparse.ArgumentParser()
	parser.add_argument("-t", "--testid", required=True, help="testid")
	parser.add_argument("-c", "--count", type=int, required=True, help="count")
	parser.add_argument("-n", "--nodes", type=int, required=True, help="nodes count")
	parser.add_argument("-D", "--disrupt", required=True, help="disrupt")
	parser.add_argument("-f", "--forwardtype", required=True, help="forward type")
	parser.add_argument("-l", "--logfile", required=True, help="logfile")
	parser.add_argument("-d", "--debug", action='store_true', default=False, help="debug")
        args = parser.parse_args()
	if args.debug:
		logger.setLevel(logging.DEBUG)
	logger.debug("startup arguments: %s" % args)



	delivered = 0
	delivered_unique = 0
	nodes = []
	with open(args.logfile, "r") as f:
		for line in f:
			m = re.search("RESULT TEST NODE: (.*)", line)
			if m:
				data = json.loads(m.group(1))
				delivered += data["delivered"]
				delivered_unique += data["delivered_unique"]
				nodes += [data["node"]]



	total_count = args.count * args.nodes
	delivered_rate = delivered / (total_count / 100.0)
	delivered_unique_rate = delivered_unique / (total_count / 100.0)
	if ( (delivered_unique_rate >= 99.9) and (delivered_unique_rate <= 100.0) ):
		result = "OK"
		ret = 0
	else:
		result = "FAILED"
		ret = 1
	results = {
		"message": "rsyslog test03 results",
		"rstest": {
			"result": result,
			"testid": args.testid,
			"disrupt": args.disrupt,
			"forward_type": args.forwardtype,
			"nodes": nodes,
			"nodes_count": len(nodes),
			"total_count": total_count,
			"delivered": delivered,
			"delivered_rate": delivered_rate,
			"delivered_unique": delivered_unique,
			"delivered_unique_rate": delivered_unique_rate
		}
	}
	logger.info("RESULT TEST TOTAL: %s" % json.dumps(results, sort_keys=True))

	try:
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.connect(("localhost", 47802))
		s.send( "%s\n" % json.dumps(results, sort_keys=True) )
		s.close()
	except Exception as e:
		logger.warning(e)

	sys.exit(ret)
