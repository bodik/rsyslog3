#!/usr/bin/python

import argparse
import logging
import netifaces
import os
import re
import shlex
import socket
import subprocess
import sys
import SimpleHTTPServer
import SocketServer
import urllib
from urlparse import urlparse, parse_qs

logger = logging.getLogger()
logging.basicConfig(level=logging.DEBUG, format='%(asctime)-15s '+os.path.basename(sys.argv[0])+'[%(process)d] %(levelname)s %(funcName)s() %(message)s')
local_ip_addresses = [netifaces.ifaddresses(iface)[netifaces.AF_INET][0]['addr'] for iface in netifaces.interfaces() if netifaces.AF_INET in netifaces.ifaddresses(iface)]




class kdc_handler(SimpleHTTPServer.SimpleHTTPRequestHandler):
	routes = {
		"/get_keytab": "get_keytab",
	}

	def do_GET(self):
		self.process_request()
	def do_POST(self):
		self.process_request()
	def process_request(self):
		if not self._same_subnet():
			self.send_response(403)
			self.end_headers()
			

		uri = urlparse(self.path).path
		try:
			if uri in self.routes.keys():
    				method = getattr(kdc_handler, self.routes[uri])
				(code, data) = method(self)
				self.send_response(code)
				self.end_headers()
				if data:
					self.wfile.write(data)
			else:
				self.send_response(404)
				self.end_headers()
	
		except Exception as e:
			logger.error("%s %s %s" % (self.client_address[0], urlparse(self.path), e))
			self.send_error(500)



	def get_keytab(self):
		if os.path.exists("/usr/sbin/kadmin.local"):
			return self._get_keytab_mit()

		if os.path.exists("/usr/bin/kadmin.heimdal"):
			return self._get_keytab_heimdal()

		return (500, "")

	def _get_keytab_mit(self):
		tmpfile = "/tmp/tmp-kadminhttp-keytab"
		hostname = self._resolve_client_address(self.client_address[0])

		try:
	                output = subprocess.check_output(shlex.split( "/usr/sbin/kadmin.local 'delprinc' 'host/%s@%s'" % (hostname, args.realm) ))
			logger.debug("delprinc: %s" % output)
		except Exception as e:
			logger.debug(e.output)

                output = subprocess.check_call(shlex.split( "/usr/sbin/kadmin.local 'ank' '-randkey' 'host/%s@%s'" % (hostname, args.realm) ))
		logger.debug("ank: %s" % output)


		if os.path.exists(tmpfile):
			os.unlink(tmpfile)
                output = subprocess.check_call(shlex.split( "/usr/sbin/kadmin.local 'ktadd' '-keytab' '%s' 'host/%s@%s'" % (tmpfile, hostname, args.realm) ))
		logger.debug("ktadd: %s" % output)

		if os.path.exists(tmpfile):
			with open(tmpfile, "r") as f:
				data = f.read()
			os.unlink(tmpfile)
				
		return (200, data)


	def _get_keytab_heimdal(self):
		tmpfile = "/tmp/tmp-kadminhttp-keytab"
		hostname = self._resolve_client_address(self.client_address[0])

		try:
	                output = subprocess.check_output(shlex.split( "/usr/bin/kadmin.heimdal --local 'delete' 'host/%s@%s'" % (hostname, args.realm) ))
			logger.debug("delprinc: %s" % output)
		except Exception as e:
			logger.debug(e.output)

                output = subprocess.check_call(shlex.split( "/usr/bin/kadmin.heimdal --local 'ank' '--use-defaults' '--random-key' 'host/%s@%s'" % (hostname, args.realm) ))
		logger.debug("ank: %s" % output)


		if os.path.exists(tmpfile):
			os.unlink(tmpfile)
                output = subprocess.check_call(shlex.split( "/usr/bin/kadmin.heimdal --local 'ext_keytab' '-k' '%s' 'host/%s@%s'" % (tmpfile, hostname, args.realm) ))
		logger.debug("ext_keytab: %s" % output)

		if os.path.exists(tmpfile):
			with open(tmpfile, "r") as f:
				data = f.read()
			os.unlink(tmpfile)
				
		return (200, data)



	def _resolve_client_address(self, ip):
		try:
			socket.setdefaulttimeout(5)
			ret = socket.gethostbyaddr(ip)[0]
		except Exception as e:
			logger.warn("%s %s" % (ip, e))
			raise e
		return ret


	def _same_subnet(self):
		if self.client_address[0] in local_ip_addresses:
			return True

		data = subprocess.check_output(shlex.split("ip neigh show")).splitlines()
		for tmp in data:
			#192.168.214.49 dev eth0 lladdr a0:f3:e4:32:86:01 REACHABLE
			pattern = "^%s dev [a-z0-9]+ lladdr ([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2}) " % self.client_address[0]
			if re.match(pattern, tmp):
				return True
		return False



		
class kdc_tcpserver(SocketServer.TCPServer):
	def server_bind(self):
        	#import socket
	        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        	self.socket.bind(self.server_address)

if __name__=="__main__":

	parser = argparse.ArgumentParser()
	parser.add_argument("--bind", default="0.0.0.0", help="bind address")
	parser.add_argument("--port", default=47900, type=int, help="bind address")
	parser.add_argument("--realm", default="RSYSLOG3", help="bind address")
	
	parser.add_argument("--debug", action='store_true', default=False, help="debug")

        args = parser.parse_args()
	logger.info("startup arguments: %s" % args)
	if args.debug:
		logger.setLevel(logging.DEBUG)



	httpd = kdc_tcpserver((args.bind, args.port), kdc_handler)
	try:
	    httpd.serve_forever()
	except KeyboardInterrupt:
	    pass
	httpd.server_close()


