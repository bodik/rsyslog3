#!/usr/bin/python

import argparse
import glob
import logging

logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, format='%(levelname)s %(message)s')

if __name__ == "__main__":

	parser = argparse.ArgumentParser()
	parser.add_argument("-n", "--node", required=True, help="client name")
	parser.add_argument("-t", "--testid", required=True, help="testid")
	parser.add_argument("-c", "--count", type=int, required=True, help="count")
        args = parser.parse_args()
	logger.info("startup arguments: %s" % args)


	print glob.glob("/var/log/hosts/2017/10/*/syslog*")


