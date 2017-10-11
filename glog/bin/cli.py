#!/usr/bin/python

import argparse
import elasticsearch
import json
import logging


logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, format='%(levelname)s %(message)s')






if __name__ == "__main__":

	parser = argparse.ArgumentParser()
	parser.add_argument("--host", default="localhost", help="elasticsearch host")
	parser.add_argument("--port", default="39200", type=int, help="elasticsearch port")
	parser.add_argument("--index", default="_all", help="elasticsearch index for action")
	parser.add_argument("--timeout", default=300, type=int, help="elasticsearch index for action")

        parser_command = parser.add_mutually_exclusive_group()
        parser_command.add_argument("--search", help="lucene query")
        parser_command.add_argument("--delete", help="lucene query")

	parser.add_argument("--debug", action='store_true', default=False, help="debug")

        args = parser.parse_args()
	logger.info("startup arguments: %s" % args)
	if args.debug:
		logger.setLevel(logging.DEBUG)


	es = elasticsearch.Elasticsearch(["http://%s:%d" % (args.host, args.port)], timeout=args.timeout)

	if args.search:
		res = es.search(index=args.index, q=args.search)

	if args.delete:
		res = es.delete_by_query(index=args.index, body={}, q=args.delete)

	print json.dumps(res, indent=4)
	
