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
import tempfile

logger = logging.getLogger()
logging.basicConfig(level=logging.DEBUG, format='%(asctime)-15s '+os.path.basename(sys.argv[0])+'[%(process)d] %(levelname)s %(message)s')
selfdir = os.path.dirname(os.path.abspath(__file__))






class Kadmin:
	def __init__(self, realm):
		self.realm = realm
		try:
			self.admin = config["admin"][self.realm]
		except:
			raise Exception("no credentials for realm %s" % self.realm)


		
	@staticmethod
	def factory(principal):
		""" returns proper class based on realm from principal"""
		if (principal.find("@") != -1):
			realm = principal.split("@")[-1]
		else:
			realm = Kadmin.guess_realm(principal)

		# TODO: move to config
		if realm in ["ZCU.CZ", "RSYSLOG3"]:
			return KadminMit(realm)
		else:
			return KadminHeimdal(realm)

	

	@staticmethod
	def guess_realm(host, path = "/etc/krb5.conf"):
		""" guess host realm by longest match of host vs domain name-realm mapping """
	
		guessed_realm = {"domain": "", "realm": None}
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
				if (host.find(domain) > -1) and (len(domain) >= len(guessed_realm["domain"])):
					guessed_realm = { "domain": domain, "realm": realm}
	
		logger.debug("guessed_realm: %s for %s" % (guessed_realm["realm"], host))
		return guessed_realm["realm"]



	@staticmethod
	def check_output(cmd):
		logger.debug(cmd)
		return subprocess.check_output(shlex.split(cmd))






class KadminMit(Kadmin):

	def exec_kadmin(self, command):
		cmd = "/usr/bin/kadmin -r {realm} -p {admin_principal} -k -t {admin_keytab} {command}".format(
			realm = self.realm, admin_principal = self.admin["principal"], admin_keytab = self.admin["keytab"], command = command)
		return self.check_output(cmd)



	def list_principals(self, principal):
		principals = self.exec_kadmin("list_principals %s" % principal).splitlines()
		return principals



	def add_principal(self, principal):
		(service, host) = principal.split("/")

		opts = []
		if service == "nfs":
			opts.append("-e des-cbc-crc:v4")

		ret = self.exec_kadmin("add_principal -randkey -policy default_nohistory +requires_preauth {opts} {principal}@{realm}".format(
			principal=principal, realm=self.realm, opts=" ".join(opts)))
		return ret




	def ktadd(self, principal, path_keytab):
		return self.exec_kadmin("ktadd -norandkey -k {path} {principal}@{realm}".format(path=path_keytab, principal=principal, realm=self.realm))
		
			
		



class KadminHeimdal(Kadmin):
	pass





def command_getkeytab(host):
	kadmin = Kadmin.factory(host)

	(tmpkeytab, path_tmpkeytab) = tempfile.mkstemp(prefix="%s-getkeytab-" % os.path.basename(sys.argv[0]))
	os.close(tmpkeytab)
	os.unlink(path_tmpkeytab)

	for service in ["host", "ftp", "pbs", "nfs"]:
		principal = "%s/%s" % (service, host)
		tmp = kadmin.list_principals(principal)
		if not tmp:
			logger.debug("must create %s@%s" % (principal, kadmin.realm))
			kadmin.add_principal(principal)
		
		kadmin.ktadd(principal, path_tmpkeytab)

	with open(path_tmpkeytab, "r") as f:
		data = f.read()

	print data




def parse_arguments():
	parser = argparse.ArgumentParser()
	parser.add_argument('--config', default=("%s/remctladmd.conf"%selfdir), help='get keytab for hostname')

	subparsers = parser.add_subparsers(dest='command')

	# command getkeytab 
	parser_getkeytab = subparsers.add_parser('getkeytab', help='getkeytab command help')
	parser_getkeytab.add_argument('--host', required=True, help='get keytab for hostname')
	#parser_getkeytab.add_argument('--services', nargs='+', required=True, help='service for hostname; can be specified multiple times')

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

