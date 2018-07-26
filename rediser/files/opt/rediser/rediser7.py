#!/usr/bin/python

import argparse
import logging
import os
import redis
import signal
import socket
import ssl
import sys
import threading
import time

logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, format='%(levelname)s %(message)s')






class Worker(threading.Thread):
	def __init__(self, client, client_address, queue):
		threading.Thread.__init__(self)
		self.setDaemon(True)
		self.name = "worker-%s:%d" % (client_address[0], client_address[1])

		self.client = client
		self.queue = queue
	

	def run(self):
		logger.info("start %s" % self.name)
		for data in self.readlines():
			self.queue.enqueue(data)
			logger.debug("%s read \"%s\"" % (self.name, data))
		if isinstance(self.client, ssl.SSLSocket):
			self.client.shutdown(socket.SHUT_RDWR)
		self.client.close()
		logger.info("exit %s" % self.name)


	def teardown(self):
		if isinstance(self.client, ssl.SSLSocket):
			self.client.shutdown(socket.SHUT_RDWR)
		self.client.close()


	def readlines(self, recv_buffer=4096, delim="\n"):
		buf = ""
		data = True
		while data:
			data = self.client.recv(recv_buffer)
			buf += data.decode("utf-8", errors='replace')

			while buf.find(delim) != -1:
				line, buf = buf.split('\n', 1)
				yield line.encode('unicode_escape', errors='replace').replace("\\\\", "\\")
		return






class Queue(threading.Thread):
	def __init__(self):
		threading.Thread.__init__(self)
		self.setDaemon(True)
		self.name = "queue"

		self.queue = []
		self.queue_lock = threading.Lock()
		self._redis_connect()


	def run(self):
		logger.info("start %s" % self.name)
		while True:
			if self.queue:
				self.flush_queue()
			else:
				time.sleep(1)
		logger.info("exit %s" % self.name)


	def teardown(self):
		logger.info("teardown start %s" % self.name)
		while(len(self.queue) > 0 ):
			self.flush_queue()
		logger.info("teardown exit %s" % self.name)
		

	def enqueue(self, data):
		self.queue_lock.acquire()
		self.queue.insert(0, data)
		self.queue_lock.release()
		while len(self.queue) > args.flushsize:
			self.flush_queue()


	def flush_queue(self):
		self.queue_lock.acquire()

		# check for queue space
		enqueue = False
		while not enqueue:
			llen = self.redis.llen(args.rediskey)
			enqueue = (llen + args.flushsize) < args.maxenqueue
			if not enqueue:
				logger.info("redis queue %s full, %d items" % (args.rediskey, llen))
				time.sleep(args.queuefullbackoff)

		# flush or reconnect
		try:
			pipeline = self.redis.pipeline()
			for i in xrange(min(len(self.queue), args.flushsize)):
				pipeline.rpush(args.rediskey, self.queue.pop())
			pipeline.execute()
		except Exception as e:
			logger.error(e)
			self._redis_connect()
		
		self.queue_lock.release()


	def _redis_connect(self):
		while True:
			try:
				self.redis = redis.StrictRedis(host=args.redishost, port=args.redisport)
				if self.redis.ping():
					return
			except:
				logger.error("redis not connected")
				time.sleep(1)






class Lister(threading.Thread):
	def __init__(self):
		threading.Thread.__init__(self)
		self.setDaemon(True)
		self.name = "lister"

	def run(self):
		while True:
			for worker in workers:
				if not worker.is_alive():
					worker.join()
					workers_lock.acquire()
					workers.remove(worker)
					workers_lock.release()
			logger.debug("workers: %s" % workers)
			time.sleep(args.listerperiod)






def teardown(signum, frame):
	logger.info("teardown start")

	server_socket.close()
	logger.info("server socket closed")

	for worker in workers:
		worker.teardown()
		worker.join(1)
	logger.info("workers stopped")

	for i in xrange(args.shutdowntimeout):
		if len(thread_queue.queue) > 0:
			logger.info("teardown waiting for queue flush (len=%d)" % len(thread_queue.queue))
			time.sleep(1)

	logger.info("teardown exit")



if __name__ == "__main__":
	workers = []
	workers_lock = threading.Lock()

	parser = argparse.ArgumentParser()
	parser.add_argument("--port", default="47800", type=int, help="port to listen for incomming connections")
	parser.add_argument("--ssl", default=None, help="key, certificate, intermediates")

	parser.add_argument("--redishost", default="localhost", help="redis server host")
	parser.add_argument("--redisport", default=16379, type=int, help="redis server port")
	parser.add_argument("--rediskey", default="test", help="redis key to write")

	parser.add_argument("--maxenqueue", default=100000, type=int, help="flush size")
	parser.add_argument("--flushsize", default=200, type=int, help="flush size")

	parser.add_argument("--queuefullbackoff", default=3, type=int, help="backoff time for flush when queue is full")
	parser.add_argument("--listerperiod", default=10, type=int, help="thread lister period")
	parser.add_argument("--shutdowntimeout", default=10, type=int, help="shutdowntimeout")
	parser.add_argument("--debug", action='store_true', default=False, help="debug")


        args = parser.parse_args()
	for loggerhadler in logger.handlers:
		loggerhadler.setFormatter(logging.Formatter("%s %s" % (args.rediskey, loggerhadler.formatter._fmt)))
	logger.info("startup arguments: %s" % args)
	if args.debug:
		logger.setLevel(logging.DEBUG)






	logging.info("startup")

	thread_lister = Lister()
	thread_lister.start()
	thread_queue = Queue()
	thread_queue.start()

	signal.signal(signal.SIGTERM, teardown)
	signal.signal(signal.SIGINT, teardown)
	try:
		server_socket = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
		server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
		server_socket.bind(("",args.port))
		server_socket.listen(5)
		if args.ssl:
			context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
			context.load_cert_chain(certfile=args.ssl)
			context.options |= ssl.OP_NO_TLSv1 | ssl.OP_NO_TLSv1_1
			context.set_ciphers("HIGH")
			#context.load_verify_locations(cafile=args.ssl)
			#context.verify_mode = ssl.CERT_REQUIRED
		while True:
	        	client, client_address = server_socket.accept()
			if args.ssl:
				try:
					client = context.wrap_socket(client, server_side=True)
				except Exception as e:
					logger.warn("%s, %s", e, client_address)
					continue
			worker = Worker(client, client_address, thread_queue)
			if worker:
				worker.start()
				workers_lock.acquire()
				workers.append(worker)
				workers_lock.release()
	except Exception as e:
		logger.error(e)
	
	logging.info("exit")
