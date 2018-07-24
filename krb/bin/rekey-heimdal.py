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

#rekey config must be enforced through env, otherwise /etc/krb5.conf could override values
os.environ["KRB5_CONFIG"] = "/etc/heimdal-kdc/kadmin-rekey.conf"
SUCCESS = 0
ERROR = 1
CHOICES = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$^&*()+/?,."
logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, stream=sys.stdout, format='%(levelname)s %(message)s')






def parse_args():
	"""parse arguments"""
	parser = argparse.ArgumentParser()
	parser.add_argument("--debug", action="store_true")
	parser.add_argument("--passwordlength", type=int, default=200)
	parser.add_argument("--keytab", required=True)
	parser.add_argument("--principal", required=True)
	parser.add_argument("--puppetstorage", default=None)
	return parser.parse_args()






def parse_principal(principal):
	"""splits principal to service, name, realm"""

	try:
		name, realm = principal.split("@")
	except Exception:
		raise ValueError("incomplete principal specified") from None

	try:
		princsvc, princname = name.split("/")
	except Exception:
		princsvc = None
		princname = name

	return (princsvc, princname, realm)






def enctypes_from_config(config):
	"""resolves default_keys/enctypes from config"""

	with open(config, "r") as ftmp:
		data = [x for x in ftmp.read().splitlines()]

	section = None
	for line in data:
		match = re.search(r"\[(?P<section>.*)\]", line)
		if match:
			section = match.group("section")
			continue

		if (section == "kadmin") and line:
			(key, value) = [x.strip() for x in line.split("=")]
			if key == "default_keys":
				return [x.replace(":pw-salt", "") for x in value.split()]

	raise RuntimeError("enctypes not detected")






def fetch(keytab):
	"""copy keytab to temporary file; returns name of the temp keytab"""

	keytab_url = urllib.parse.urlparse(keytab, scheme="file")
	with tempfile.NamedTemporaryFile(prefix="/dev/shm/rekey_heimdal_", delete=False) as ftmp:
		keytab_temp = ftmp.name
	logger.debug("keytab_temp: %s", keytab_temp)

	logger.info("fetch:: keytab from %s to temporary location %s", keytab, keytab_temp)

	if keytab_url.scheme == "file":
		try:
			subprocess.check_call(shlex.split("cp --archive %s %s" % (keytab_url.path, keytab_temp)))
		except Exception:
			os.unlink(keytab_temp)
			raise RuntimeError("cannot fetch keytab") from None


	elif keytab_url.scheme == "ssh":
		try:
			subprocess.check_call(shlex.split("scp %s:%s %s" % (keytab_url.netloc, keytab_url.path, keytab_temp)), stdout=subprocess.DEVNULL)
		except Exception:
			os.unlink(keytab_temp)
			raise RuntimeError("cannot fetch keytab") from None


	else:
		os.unlink(keytab_temp)
		raise RuntimeError("invalid keytab specified")


	keytab_listing = subprocess.check_output(shlex.split("ktutil --verbose --keytab=%s list" % keytab_temp)).decode("UTF-8")
	logger.debug("original keytab contents: %s", "\n".join(map(lambda x: "> "+x, keytab_listing.splitlines())))
	return keytab_temp








def generate_new_keys(keytab, principal, password_length):
	"""generates new keys for principal, returns new password"""

	logger.info("generate_new_keys:: kdb kvno detection")
	kdb_kvno = -1
	_, _, realm = parse_principal(principal)
	try:
		principal_listing = subprocess.check_output(shlex.split("kadmin.heimdal --local --realm=%s get %s" % (realm, principal))).decode("UTF-8")
		for line in principal_listing.splitlines():
			if line.strip().startswith("Kvno:"):
				kdb_kvno = int(line.strip().split(" ")[-1])
				break
	except Exception as e:
		logger.error(e)
	if kdb_kvno <= 0:
		raise RuntimeError("cannot detect current kvno from kdb") from None
	logger.debug("kdb detected kvno: %s", kdb_kvno)



	logger.info("generate_new_keys:: keytab kvno detection")
	keytab_kvno = -1
	try:
		keytab_listing = subprocess.check_output(shlex.split("ktutil --verbose --keytab=%s list" % keytab)).decode("UTF-8")
		for line in keytab_listing.splitlines():
			match = re.match(r"\s*(?P<kvno>\d+)\s+(?P<enctype>\S+)\s+(?P<principal>\S+)\s+(?P<date>\S+)\s*", line.strip())
			if match and (match.group("principal") == principal) and (int(match.group("kvno")) > keytab_kvno):
				keytab_kvno = int(match.group("kvno"))
	except Exception as e:
		logger.error(e)

	if keytab_kvno <= 0:
		raise RuntimeError("cannot detect current kvno from keytab") from None
	logger.debug("keytab detected kvno: %s", keytab_kvno)



	logger.info("generate_new_keys:: kvno match check")
	if kdb_kvno != keytab_kvno:
		raise RuntimeError("kdb and keytab kvnos does not match")



	logger.info("generate_new_keys:: put new keys to keytab")
	password = "".join([random.SystemRandom().choice(CHOICES) for _ in range(password_length)])
	try:
		for enctype in enctypes_from_config(os.getenv("KRB5_CONFIG")):
			password_key = subprocess.check_output(shlex.split( \
				"string2key --principal=%s --keytype=%s %s" % (principal, enctype, password))).decode("UTF-8").split(" ")[-1]
			subprocess.check_call(shlex.split( \
				"ktutil --keytab=%s add --enctype=%s --principal=%s --kvno=%s --hex --password=%s" % (keytab, enctype, principal, kdb_kvno+1, password_key)))
	except Exception as e:
		logger.error(e)
		raise RuntimeError("cannot add new key to keytab") from None


	keytab_listing = subprocess.check_output(shlex.split("ktutil --verbose --keytab=%s list" % keytab)).decode("UTF-8")
	logger.debug("new keys keytab contents: %s", "\n".join(map(lambda x: "> "+x, keytab_listing.splitlines())))
	return password






def put(keytab_temp, keytab, puppet_storage):
	"""update keytab with backup"""

	keytab_url = urllib.parse.urlparse(keytab, scheme="file")

	logger.info("put:: writeback updated keytab")

	if keytab_url.scheme == "file":
		try:
			subprocess.check_call(shlex.split("cp --archive %s %s.rekeybackup.%s" % (keytab_url.path, keytab_url.path, time.time())))
			subprocess.check_call(shlex.split("cp --archive %s %s" % (keytab_temp, keytab_url.path)))
		except Exception:
			raise RuntimeError("cannot put keytab") from None


	elif keytab_url.scheme == "ssh":
		try:
			if puppet_storage:
				logger.info("put:: suspend puppet on managed node")
				subprocess.check_call(["ssh", keytab_url.netloc, "if [ -x /usr/local/sbin/puppet-stop ]; then /usr/local/sbin/puppet-stop rekey; while [ -n \"$(pgrep -f '^/usr/bin/ruby /usr/bin/puppet agent')\" ]; do sleep 1; done; fi"])
				puppet_storage_url = urllib.parse.urlparse(puppet_storage)
				logger.info("put:: upload keytab to puppetstorage")
				subprocess.check_call(shlex.split("scp %s %s:%s" % (keytab_temp, puppet_storage_url.netloc, puppet_storage_url.path)), stdout=subprocess.DEVNULL)

			logger.info("put:: upload keytab to managed node")
			subprocess.check_call(shlex.split("ssh %s 'cp --archive %s %s.rekeybackup.%s'" % (keytab_url.netloc, keytab_url.path, keytab_url.path, time.time())))
			subprocess.check_call(shlex.split("scp %s %s:%s" % (keytab_temp, keytab_url.netloc, keytab_url.path)), stdout=subprocess.DEVNULL)

			if puppet_storage:
				logger.info("put:: activate puppet on managed node")
				subprocess.check_call(shlex.split("ssh %s 'if [ -x /usr/local/sbin/puppet-start ]; then /usr/local/sbin/puppet-start rekey; fi'" % keytab_url.netloc))

		except Exception as e:
			logger.error(e)
			raise RuntimeError("cannot put keytab") from None


	else:
		raise NotImplementedError


	return True






def kdb_cpw(principal, password):
	"""update principals password; override default_keys forcing new keys with requested enctypes"""

	_, _, realm = parse_principal(principal)
	logger.info("kdb_cpw:: update managed principal")
	try:
		subprocess.check_call(shlex.split("kadmin.heimdal --local --realm=%s cpw --password=%s %s" % (realm, password, principal)))
	except Exception:
		raise RuntimeError("cannot cpw for principal") from None

	principal_listing = subprocess.check_output(shlex.split("kadmin.heimdal --local --realm=%s get %s" % (realm, principal))).decode("UTF-8")
	logger.debug("updated principal: %s", "\n".join(map(lambda x: "> "+x, principal_listing.splitlines())))
	return True






def main():
	"""main"""
	args = parse_args()
	if args.debug:
		logger.setLevel(logging.DEBUG)
	logger.debug(args)
	_, _, _ = parse_principal(args.principal)
	if not os.path.exists(os.getenv("KRB5_CONFIG")):
		logger.error("missing rekey config")
		return ERROR

	try:
		keytab_temp = fetch(args.keytab)
		password = generate_new_keys(keytab_temp, args.principal, args.passwordlength)
		put(keytab_temp, args.keytab, args.puppetstorage)
		kdb_cpw(args.principal, password)
		os.unlink(keytab_temp)
	except Exception as e:
		logger.error(e)
		return ERROR

	logger.info("main:: finished")
	return SUCCESS



if __name__ == "__main__":
	sys.exit(main())
