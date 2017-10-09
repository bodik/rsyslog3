#!/usr/bin/python

import argparse
import logging
import os
import signal
import socket
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
	logger.info("RESULT: written %d" % count)
	sys.exit(0)


def writer():
	global count
	
	f = open("/dev/urandom" ,"r")
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.connect((args.host, args.port))

	i = args.batch
	# if there's a bulk to send, we grab last message as stopper for perftest
	if args.batch > 1:
		i -= 1
	while ( i != 0 ):
		data = "".join(["{:02x}".format(ord(x)) for x in  f.read(100)])
		s.send("%s perftestmessage \\n tmsg%d %s\n" % (args.id, count, str(data)))
		i -= 1
		count += 1

	if args.batch > 1:
		s.send("STOPSTOPSTOP %s perftestmessage \\n tmsg%d %s\n" % (args.id, count, str(data)))
		count += 1

	s.close()
	f.close()

if __name__ == "__main__":
	count = 0

        parser = argparse.ArgumentParser()
	parser.add_argument("--host", default="localhost", help="rediser server host")
	parser.add_argument("--port", default=47800, type=int, help="rediser server port")
	parser.add_argument("--report", default=1, type=int, help="test id")
	parser.add_argument("--id", default="auto", help="test id")
	parser.add_argument("--batch", default=100, type=int, help="number of messages to write; -1 is infinite")
        args = parser.parse_args()

	signal.signal(signal.SIGTERM, teardown)
	signal.signal(signal.SIGINT, teardown)
	try:
		reporter = threading.Thread(target=reporter)
		reporter.setDaemon(True)
		reporter.start()

		writer()
	except Exception as e:
		logger.error(e)
		teardown(None, None)

	teardown(None, None)
