#!/usr/bin/python

import argparse
import base64
import ConfigParser
import inspect
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




### kadmin automation classes
###

class Kadmin:
	""" root class for kadmin automation """

	def __init__(self, realm):
		self.realm = realm

		if self.realm in config["realm"]:
			self.admin = config["realm"][self.realm]
		else:
			raise Exception("no credentials for realm %s" % self.realm)


		
	@staticmethod
	def factory(principal):
		""" returns proper class based on realm from principal"""
		if (principal.find("@") != -1):
			realm = principal.split("@")[-1]
		else:
			realm = Kadmin.guess_realm(principal)

		try:
			# instantiate class by name referenced in config as a string
			return globals()[config["realm"][realm]["type"]](realm)
		except:
			raise Exception("realm %s not properly configured" % realm)

	

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






class KadminMit(Kadmin):

	def exec_kadmin(self, command):
		cmd = "/usr/bin/kadmin -r {realm} -p {admin_principal} -k -t {admin_keytab} {command}".format(
			realm = self.realm, admin_principal = self.admin["principal"], admin_keytab = self.admin["keytab"], command = command)
		logger.debug(cmd)
		return subprocess.check_output(shlex.split(cmd))



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





### authorization framework
###

class NotAuthorizedException(Exception):
	""" raised when user is not authorized to perform requested action """

def check_by_regexp(regexp, val):
	""" evaluate value to regexp respecting type of value """
	if isinstance(val, list):
		for item in val:
			if not re.match(regexp, item): return False
	else:
		if not re.match(regexp, val): return False

	return True

def is_authorized(**kwargs):
	caller = inspect.currentframe().f_back.f_code.co_name

	# caller command has not configured any constraints >> default deny
	if caller not in config["acls"]: raise NotAuthorizedException("is_authorized denied %s to %s:%s" % (remoteuser, caller, kwargs))
		
	# evaluate every acl for given command
	for acl in config["acls"][caller]:
			if acl["group"] not in config["groups"]: continue
	
			# if user is in group check all arguments passed by the caller
			if remoteuser in config["groups"][acl["group"]]:
				kwargs_result = [check_by_regexp(acl[argname], argvalue) for argname, argvalue in kwargs.iteritems()]
				# and if all arguments matches, result as permitted
				if all(kwargs_result):
					logger.debug("is_authorized permitted %s to %s:%s" % (remoteuser, caller, kwargs))
					return True

	# no match has been found >> default deny
	raise NotAuthorizedException("is_authorized denied %s to %s:%s" % (remoteuser, caller, kwargs))






### commands implementation
###

def createkeytab(host, services):
	is_authorized(host=host, services=services)

	kadmin = Kadmin.factory(host)
	host = host.split("@")[0] # strip realm if present

	# create temporary filename
	with tempfile.NamedTemporaryFile(prefix="%s-getkeytab-" % os.path.basename(sys.argv[0])) as tmpkeytab:
		path_tmpkeytab = tmpkeytab.name

	# upsert principals and create keytab
	for service in services:
		principal = "%s/%s" % (service, host)
		tmp = kadmin.list_principals(principal)
		if not tmp:
			logger.debug("must create %s@%s" % (principal, kadmin.realm))
			kadmin.add_principal(principal)
		
		kadmin.ktadd(principal, path_tmpkeytab)

	# return the keytab
	with open(path_tmpkeytab, "r") as f:
		print base64.b64encode(f.read())
	os.unlink(path_tmpkeytab)






def storesshhostkey(host, filename, data):
	is_authorized(host=host, filename=filename)

	destdir = os.path.realpath("%s/%s" % (config["ssh-key-storage"], host))
	if not destdir.startswith(config["ssh-key-storage"]):
		raise Exception("invalid host")
	destfile = os.path.realpath("%s/%s" % (destdir, filename))
	if not destfile.startswith(destdir):
		raise Exception("invalid filename")

	if not os.path.exists(destdir):
		os.makedirs(destdir)
	with open(destfile, "w") as f:
		f.write(base64.b64decode(data))
	os.chmod(destfile, 0600)
	logger.debug("%s:%s stored in %s" % (host, filename, destfile))






def getsshhostkey(host, filename):
	is_authorized(host=host, filename=filename)

	destdir = os.path.realpath("%s/%s" % (config["ssh-key-storage"], host))
	if not destdir.startswith(config["ssh-key-storage"]):
		raise Exception("invalid host")
	destfile = os.path.realpath("%s/%s" % (destdir, filename))
	if not destfile.startswith(destdir):
		raise Exception("invalid filename")

        with open(destfile, "r") as f:
                print base64.b64encode(f.read())
	logger.debug("%s read from %s:%s" % (filename, host, destfile))





### main and utils
###

def parse_arguments():
	parser = argparse.ArgumentParser()

	subparsers = parser.add_subparsers(dest='command')

	parser_conftest = subparsers.add_parser("conftest", help="configtest help")

	parser_createkeytab = subparsers.add_parser("createkeytab", help="createkeytab command help")
	parser_createkeytab.add_argument("--host", required=True, help="create (upsert principals) keytab for hostname")
	parser_createkeytab.add_argument("--services", required=True, nargs="+", help="create (upsert principals) keytab for services at hostname")

	parser_storesshhostkey = subparsers.add_parser("storesshhostkey", help="createkeytab command help")
	parser_storesshhostkey.add_argument("--host", required=True, help="hostname to store key for")
	parser_storesshhostkey.add_argument("--filename", required=True, help="filename")
	parser_storesshhostkey.add_argument("--data", required=False, help="base64 encoded data to store")

	parser_getsshhostkey = subparsers.add_parser("getsshhostkey", help="getsshhostkey command help")
	parser_getsshhostkey.add_argument("--host", required=True, help="get file for hostname")
	parser_getsshhostkey.add_argument("--filename", required=True, help="filename to get from storage")


        # finish parsing        
        args = parser.parse_args()
        return args



if __name__ == "__main__":

	# startup 
	remoteuser = os.getenv("REMOTE_USER", "UNAUTHENTICATED")
	logger.debug("authenticated as %s" % remoteuser)
	args = parse_arguments()
	logger.debug("startup arguments: %s" % args)
	with open( "%s/remctladmd.conf" % os.path.dirname(os.path.abspath(__file__)), "r") as f:
		config = json.loads(f.read())

	# process command	
	if (args.command == "conftest"):
		logger.info("configuration: %s" % config)

	if (args.command == "createkeytab"):
		createkeytab(args.host, args.services)

	if (args.command == "storesshhostkey"):
		storesshhostkey(args.host, args.filename, args.data)

	if (args.command == "getsshhostkey"):
		getsshhostkey(args.host, args.filename)

