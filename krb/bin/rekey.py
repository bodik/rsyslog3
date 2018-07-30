#!/usr/bin/env python3
"""perform principal rekey"""


import argparse
import logging
import os
import random
import re
import shlex
import subprocess
import sys
import tempfile
import time
import urllib.parse




##rekey config must be enforced through env, otherwise /etc/krb5.conf could override values
os.environ["KRB5_CONFIG"] = "/etc/heimdal-kdc/kadmin-rekey.conf"
SUCCESS, ERROR = 0, 1
logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, stream=sys.stdout, format='%(levelname)s %(message)s')




### kadmin automation
###
class Kadmin(object):
	"""root class for kadmin automation"""

	def __init__(self, realm, kadmin_binary):
		self.log = logging.getLogger()
		self.realm = realm
		self.kadmin_binary = kadmin_binary




	@staticmethod
	def enctypes_from_config():
		"""resolves default_keys/enctypes from config"""

		ret = []
		section = None

		with open(os.getenv("KRB5_CONFIG", "/etc/krb5.conf"), "r") as ftmp:
			data = [x for x in ftmp.read().splitlines()]
		for line in data:
			match = re.search(r"\[(?P<section>.*)\]", line)
			if match:
				section = match.group("section")
				continue
	
			if (section == "kadmin") and line:
				try:
					(key, value) = [x.strip() for x in line.split("=")]
				except Exception:
					continue
				if key == "default_keys":
					ret += [x.replace(":pw-salt", "") for x in value.split()]

		return ret




	@staticmethod
	def guess_realm(host):
		"""guess host realm by longest match of host vs domain name-realm mapping"""

		if host.find("@") != -1:
			return host.split("@")[-1]

		# cannot be parsed by ConfigParser due to realm syntax
		guessed_realm = {"domain": "", "realm": None}
		section = None
		with open(os.getenv("KRB5_CONFIG", "/etc/krb5.conf"), "r") as tmpfile:
			data = [x.strip() for x in tmpfile.readlines()]
		for line in data:
			match = re.search(r"\[(?P<section>.*)\]", line)
			if match:
				section = match.group("section")
				continue

			if (section == "domain_realm") and line:
				try:
					(domain, realm) = [x.strip() for x in line.split("=")]
				except Exception:
					continue
				# most specific match must win
				if (host.find(domain) > -1) and (len(domain) >= len(guessed_realm["domain"])):
					guessed_realm = {"domain": domain, "realm": realm}

		return guessed_realm["realm"]




	@staticmethod
	def canonicalize_name(name):
		if name.find("@") > -1:
			return name
		else:
			realm = Kadmin.guess_realm(name)
			if realm:
				return "%s@%s" % (name, realm)
			else:
				raise RuntimeError("cannot canonicalize name %s" % name)






class KadminLocalHeimdal(Kadmin):
	""" rekey kadmin implementation for Heimdal Kerberos """

	@staticmethod
	def keytab_list(keytab):
		return subprocess.check_output(shlex.split("ktutil --verbose --keytab=%s list" % keytab)).decode("UTF-8")




	@staticmethod
	def keytab_addkey(keytab, principal, kvno, enctype, password):
		password_key = subprocess.check_output(shlex.split( \
			"string2key --principal=%s --keytype=%s %s" % (principal, enctype, password))).decode("UTF-8").split(" ")[-1]
		subprocess.check_output(shlex.split( \
			"ktutil --keytab=%s add --principal=%s --kvno=%s --enctype=%s --hex --password=%s" % (keytab, principal, kvno, enctype, password_key)))
		return True




	def exec_kadmin(self, command):
		"""execute kadmin command"""

		cmd = "{kadmin} --local --realm={realm} {command}".format( \
			kadmin=self.kadmin_binary, realm=self.realm, command=command)
		self.log.debug(cmd)
		return subprocess.check_output(shlex.split(cmd)).decode("UTF-8")




	def principal_get(self, principal):
		return self.exec_kadmin("get %s" % principal)




	def principal_kvno(self, principal):
		for line in self.principal_get(principal).splitlines():
			if line.strip().startswith("Kvno:"):
				return int(line.strip().split(" ")[-1])
		raise RuntimeError("cannot get principal's kvno from kdb")




	def cpw(self, principal, password):
		return self.exec_kadmin("cpw --password=%s %s" % (password, principal))






class Rekeyer(object):
	CHOICES = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$^&*()+/?,."
	PASSWORD_LENGTH = 200
	PUPPET_SUSPEND = "if [ -x /usr/local/sbin/puppet-stop ]; then /usr/local/sbin/puppet-stop rekey; while [ -n \"$(pgrep -f '^/usr/bin/ruby /usr/bin/puppet agent')\" ]; do sleep 1; done; fi"
	PUPPET_ACTIVATE = "if [ -x /usr/local/sbin/puppet-start ]; then /usr/local/sbin/puppet-start rekey; fi"

	
	def __init__(self, kadmin, keytab):
		self.log = logging.getLogger()
		self.kadmin = kadmin
		self.keytab_url = urllib.parse.urlparse(keytab, scheme="file")
		with tempfile.NamedTemporaryFile(prefix="/dev/shm/rekey_", delete=False) as ftmp:
			self.keytab_temp = ftmp.name
		self.log.debug("keytab_temp: %s", self.keytab_temp)




	@staticmethod
	def subprocess_check_output(cmd, errstr):
		try:
			if isinstance(cmd, str):
				cmd = shlex.split(cmd) 
			return subprocess.check_output(cmd, stderr=subprocess.PIPE).decode("UTF-8")
		except Exception as e:
			logging.error(e)
			raise RuntimeError(errstr) from None




	def fetch_keytab(self):
		"""copy keytab to temporary file"""
		
		self.log.info("fetch:: keytab from %s to temporary location %s", self.keytab_url.geturl(), self.keytab_temp)

		if self.keytab_url.scheme == "file":
			self.subprocess_check_output( \
				"cp --archive %s %s" % (self.keytab_url.path, self.keytab_temp),
				"cannot fetch keytab")

		elif self.keytab_url.scheme == "ssh":
			self.subprocess_check_output( \
				"scp %s:%s %s" % (self.keytab_url.netloc, self.keytab_url.path, self.keytab_temp),
				"cannot fetch keytab")

		else:
			raise RuntimeError("invalid keytab specified")

		self.log.debug("temporary keytab contents: %s", self.kadmin.keytab_list(self.keytab_temp))
		return SUCCESS




	def new_key_to_keytab(self, principal):
		"""generates new keys for principal, returns new password"""
	
		self.log.info("new_keys:: generate new key to keytab")

		kdb_kvno = self.kadmin.principal_kvno(principal)
		self.log.debug("principal's kdb kvno: %s", kdb_kvno)
	
		keytab_kvno = -1
		for line in self.kadmin.keytab_list(self.keytab_temp).splitlines():
			match = re.match(r"\s*(?P<kvno>\d+)\s+(?P<enctype>\S+)\s+(?P<principal>\S+)\s+(?P<date>\S+)\s*", line.strip())
			if match and (match.group("principal") == principal) and (int(match.group("kvno")) > keytab_kvno):
				keytab_kvno = int(match.group("kvno"))
		if keytab_kvno < 1:
			raise RuntimeError("cannot detect current kvno from keytab")
		self.log.debug("principal's keytab kvno: %s", keytab_kvno)
	
		if kdb_kvno != keytab_kvno:
			raise RuntimeError("kdb and keytab kvnos does not match")
	
	
		password = "".join([random.SystemRandom().choice(self.CHOICES) for _ in range(self.PASSWORD_LENGTH)])
		try:
			for enctype in self.kadmin.enctypes_from_config():
				self.kadmin.keytab_addkey(self.keytab_temp, principal, kdb_kvno+1, enctype, password)
		except Exception as e:
			self.log.error(e)
			raise RuntimeError("cannot add new key to keytab") from None
	
	
		self.log.debug("keytab with new keys contents: %s", self.kadmin.keytab_list(self.keytab_temp))
		return password




	def update_keytab(self, puppet_storage):
		"""update keytab with backup"""
	
		self.log.info("put:: writeback updated keytab")
	
		if self.keytab_url.scheme == "file":
			self.subprocess_check_output( \
				"cp --archive %s %s.rekeybackup.%s" % (self.keytab_url.path, self.keytab_url.path, time.time()),
				"cannot backup keytab")
			self.subprocess_check_output( \
				"cp --archive %s %s" % (self.keytab_temp, self.keytab_url.path),
				"cannot put keytab")
	
		elif self.keytab_url.scheme == "ssh":
			if puppet_storage:
				self.log.info("put:: suspend puppet on managed node")
				self.subprocess_check_output( \
					["ssh", self.keytab_url.netloc, self.PUPPET_SUSPEND],
					"cannot suspend puppet agent")

				self.log.info("put:: upload keytab to puppetstorage")
				puppet_storage_url = urllib.parse.urlparse(puppet_storage)
				self.subprocess_check_output( \
					"scp %s %s:%s" % (self.keytab_temp, puppet_storage_url.netloc, puppet_storage_url.path),
					"cannot upload updated keytab to puppetstorage")
	
			self.log.info("put:: upload keytab to managed node")
			self.subprocess_check_output( \
				"ssh %s 'cp --archive %s %s.rekeybackup.%s'" % (self.keytab_url.netloc, self.keytab_url.path, self.keytab_url.path, time.time()),
				"cannot backup keytab")
			self.subprocess_check_output( \
				"scp %s %s:%s" % (self.keytab_temp, self.keytab_url.netloc, self.keytab_url.path),
				"cannot upload updated keytab")
	
			if puppet_storage:
				self.log.info("put:: activate puppet on managed node")
				self.subprocess_check_output( \
					["ssh", self.keytab_url.netloc, self.PUPPET_ACTIVATE],
					"cannot activate puppet agent")
	
		else:
			raise NotImplementedError

		return True




	def update_kdb(self, principal, password):
		"""update principals password; override default_keys forcing new keys with requested enctypes"""
	
		self.log.info("update_kdb:: update managed principal")

		try:
			self.kadmin.cpw(principal, password)
		except Exception:
			raise RuntimeError("cannot update principal") from None

		logger.debug("updated principal: %s", self.kadmin.principal_get(principal))
		return True




	def drop_old_keys_from_keytab(self, principal):
		"""fetch principal info from kdb, purge all non-corresponding keys from keytab"""
	
		self.log.info("drop_old_keys_from_keytab:: cleaning up keytab")

		kdb_kvno = None
		kdb_enctypes = []
		try:
			for line in self.kadmin.principal_get(principal).splitlines():
				if line.strip().startswith("Kvno:"):
					kdb_kvno = int(line.strip().split(" ")[-1])
	
				if line.strip().startswith("Keytypes:"):
					for enctype in line.strip().split(":")[1].split(","):
						match = re.match(r"\s*(?P<enctype>.*)\((?P<salt>.*)\)\[(?P<kvno>\d+)\]", enctype)
						if match:
							kdb_enctypes.append(match.group("enctype"))
		except Exception as e:
			self.log.error(e)
		if (not kdb_kvno) or (not kdb_enctypes):
			raise RuntimeError("fetching principal info from kdb failed")
		self.log.debug("principal %s, kvno %d, enctypes %s", principal, kdb_kvno, kdb_enctypes)
	
	
		try:
			for line in self.kadmin.keytab_list(self.keytab_temp).splitlines():
				match = re.match(r"\s*(?P<kvno>\d+)\s+(?P<enctype>\S+)\s+(?P<principal>\S+)\s+(?P<date>\S+)\s*", line.strip())
				if match and (match.group("principal") == principal) and ((match.group("enctype") not in kdb_enctypes) or (int(match.group("kvno")) != kdb_kvno)):
					self.log.debug("removing: %s", line)
					self.subprocess_check_output( \
						"ktutil --keytab=%s remove --principal=%s --kvno=%s --enctype=%s" % (self.keytab_temp, principal, int(match.group("kvno")), match.group("enctype")),
						"cannot remove key from keytab")
					try:
						self.subprocess_check_output( \
							"kdestroy --credential=%s" % principal,
							"cannot flush cached tgs")
					except Exception as e:
						pass
		except Exception as e:
			self.log.error(e)
			raise RuntimeError("pruning keytab failed") from None
	
		logger.debug("pruned keytab contents: %s", self.kadmin.keytab_list(self.keytab_temp))
		return True




	def cleanup(self):
		"""cleanup"""

		if os.path.exists(self.keytab_temp):
			os.unlink(self.keytab_temp)
		return SUCCESS






def parse_args():
	"""parse arguments"""
	parser = argparse.ArgumentParser()
	parser.add_argument("--debug", action="store_true", help="print debug messages")
	parser.add_argument("--keytab", required=True, help="keytab to manage")
	parser.add_argument("--principal", required=True, help="principal to manage")
	parser.add_argument("--puppetstorage", default=None, help="URI to configuration management storage")
	parser.add_argument("--action", default="rekey", choices=["rekey", "cleanupkeytab"], help="requested operation; default is 'rekey'")
	return parser.parse_args()



def main():
	"""main"""
	args = parse_args()
	if args.debug:
		logger.setLevel(logging.DEBUG)
	logger.debug(args)

	if not os.path.exists(os.getenv("KRB5_CONFIG", "/etc/krb5.conf")):
		logger.error("missing rekey config")
		return ERROR


	full_principal = Kadmin.canonicalize_name(args.principal)
	kadmin = KadminLocalHeimdal(full_principal.split("@")[-1], "/usr/bin/kadmin.heimdal")
	rekeyer = Rekeyer(kadmin, args.keytab)


	rekeyer.fetch_keytab()

	if args.action == "rekey":
		password = rekeyer.new_key_to_keytab(full_principal)
	elif args.action == "cleanupkeytab":
		rekeyer.drop_old_keys_from_keytab(full_principal)

	rekeyer.update_keytab(args.puppetstorage)

	if args.action == "rekey":
		rekeyer.update_kdb(full_principal, password)

	rekeyer.cleanup()


	logger.info("main:: finished")
	return SUCCESS



if __name__ == "__main__":
	sys.exit(main())
