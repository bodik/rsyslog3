#!/usr/bin/python

import argparse
import ConfigParser
import json
import logging
import os
import re
import shlex
import StringIO
import subprocess
import sys

logger = logging.getLogger()
logging.basicConfig(level=logging.DEBUG, format='%(asctime)-15s '+os.path.basename(sys.argv[0])+'[%(process)d] %(levelname)s %(message)s')
selfdir = os.path.dirname(os.path.abspath(__file__))




class Kadmin:
	def __init__(self, host, realm):
		self.fqdn = host
		self.realm = realm

		try:
			self.admin = config["admin"][self.realm]
		except:
			raise Exception("no credentials for realm %s" % self.realm)


		
	@staticmethod
	def factory(host):
		""" returns proper class based on realm """
		if (host.find("@") != -1):
			(fqdn, realm) = host.split("@")
		else:
			(fqdn, realm) = (host, Kadmin.guess_realm(host))

		if realm in ["ZCU.CZ", "RSYSLOG3"]:
			return KadminMit(host, realm)
		else:
			return KadminHeimdal(host, realm)

	

	@staticmethod
	def guess_realm(host, path = "/etc/krb5.conf"):
		""" guess host realm by longest match of host vs domain name-realm mapping """
	
		guessed_realm = ("", None)
		section = None
	
		with open(path) as f: data = [x.strip() for x in f.read().splitlines()]
		for line in data:
			m = re.search("\[(?P<section>.*)\]",line)
			if m:
				section = m.group("section")
				continue
	
			if (section == "domain_realm") and line:
				(domain, realm) = [x.strip() for x in line.split("=")]
				# most specific match must win
				if (host.find(domain) > -1) and (len(domain) >= len(guessed_realm[0])):
					guessed_realm = (domain, realm)
	
		logger.debug("guessed_realm: %s for %s" % (realm, host))
		return guessed_realm[1]

	@staticmethod
	def check_output(cmd):
		logger.debug(cmd)
		return subprocess.check_output(shlex.split(cmd))




class KadminMit(Kadmin):
	kadminbin = "/usr/bin/kadmin"

	def list_principals(self, service):
		cmd = "{kadminbin} -r {realm} -p {admin_principal} -k -t {admin_keytab} list_principals '{service}/{fqdn}@{realm}'".format(
			kadminbin = self.kadminbin, realm = self.realm, admin_principal = self.admin["principal"], admin_keytab = self.admin["keytab"],
			service = service, fqdn = self.fqdn)
		logger.info(self.check_output(cmd).splitlines())
		



class KadminHeimdal(Kadmin):
	pass





def command_getkeytab(host):
	kadmin = Kadmin.factory(host)
	kadmin.list_principals("host")





def parse_arguments():
	parser = argparse.ArgumentParser()
	parser.add_argument('--config', default=("%s/remctladmd.conf"%selfdir), help='get keytab for hostname')

	subparsers = parser.add_subparsers(dest='command')

	# command getkeytab 
	parser_getkeytab = subparsers.add_parser('getkeytab', help='getkeytab command help')
	parser_getkeytab.add_argument('--host', required=True, help='get keytab for hostname')
	parser_getkeytab.add_argument('--services', nargs='+', required=True, help='get keytab for hostname')

        # finish parsing        
        args = parser.parse_args()
        return args


if __name__ == "__main__":

	args = parse_arguments()
	logger.debug("startup arguments: %s" % args)
	with open(args.config, "r") as f:
		config = json.loads(f.read())
	logger.debug("configuration: %s" % config)

	if (args.command) == "getkeytab":
		command_getkeytab(args.host)

