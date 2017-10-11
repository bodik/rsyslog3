#!/usr/bin/python

import argparse
import json
import logging
import os
import shlex
import signal
import subprocess
import sys

logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, format='%(levelname)s %(message)s')
selfdir = os.path.dirname(os.path.abspath(__file__))
workerbin = "%s/rediser7.py" % selfdir






def teardown(signum, frame):
	logger.info("teardown start")

	for worker in workers:
		worker.poll()
		if worker.returncode == None:
			worker.terminate()
		worker.wait()
		
	logger.info("teardown exit")



if __name__ == "__main__":
	workers = []

	parser = argparse.ArgumentParser()
	parser.add_argument("--config", default="%s/rediser.conf" % selfdir, help="rediser configuration file path")
	parser.add_argument("--dry", action='store_true', default=False, help="parse and print startup config")
	parser.add_argument("--debug", action='store_true', default=True, help="debug output")
        args = parser.parse_args()
	for loggerhadler in logger.handlers:
		loggerhadler.setFormatter(logging.Formatter("%s %s" % ("master", loggerhadler.formatter._fmt)))
	logger.info("startup arguments: %s" % args)
	if args.debug:
		logger.setLevel(logging.DEBUG)

	with open(args.config, "r") as f:
		config = json.loads(f.read())
	logging.debug("config: %s" % config)
	if args.dry:
		logging.info("config: %s" % config)
		sys.exit(0)



	logging.info("startup")

	signal.signal(signal.SIGTERM, teardown)
	signal.signal(signal.SIGINT, teardown)

	for instance in config.keys():
		args = " ".join(["--%s '%s'"%(k,v) for k,v in config[instance].iteritems()])
		cmd = shlex.split("%s %s" % (workerbin, args))
		p = subprocess.Popen(cmd)
		workers.append(p)

	for i in workers:
		i.wait()

	teardown(None, None)
	logging.info("exit")

