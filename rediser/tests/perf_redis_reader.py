#!/usr/bin/python

import argparse
import logging
import os
import redis
import signal
import sys
import time
import threading

logger = logging.getLogger()
logging.basicConfig(level=logging.DEBUG, format='%(asctime)-15s '+os.path.basename(sys.argv[0])+'[%(process)d] %(levelname)s %(message)s')


def reporter():
	global count
	while True:
		logger.debug("report %d" % count)
		time.sleep(args.report)


def teardown(signum, frame):
	global count
	logger.info("RESULT: read %d" % count)
	sys.exit(0)


def reader():
	global count
	stop = False

	while True:
		r = redis.StrictRedis(host=args.host, port=args.port)
		while not stop:
			if args.batch > 1:
				pipe = r.pipeline()
				for i in xrange(args.batch):
					pipe.lpop(args.key)
				result = pipe.execute()
				for i in result:
					if i:
						count += 1
						if i.startswith(args.stop):
							stop = True
			else:
				print r.blpop(args.key)
		if stop:	
			logger.info("stop by message")
			return


if __name__ == "__main__":
	count = 0

        parser = argparse.ArgumentParser()
	parser.add_argument("--host", default="localhost", help="redis sert host")
	parser.add_argument("--port", default=16379, type=int, help="redis server port")
	parser.add_argument("--key", default="test", help="redis key to read")
	parser.add_argument("--report", default=1, type=int, help="test id")
	parser.add_argument("--batch", default=100, type=int, help="batch size for reading pipeline")
	parser.add_argument("--stop", default="STOPSTOPSTOP", help="stop message")
        args = parser.parse_args()

	signal.signal(signal.SIGTERM, teardown)
	signal.signal(signal.SIGINT, teardown)
	try:
		reporter = threading.Thread(target=reporter)
		reporter.setDaemon(True)
		reporter.start()

		reader()
	except Exception as e:
		logger.error(e)
		teardown(None, None)
	
	teardown(None, None)

