#!/usr/bin/env python3
"""perform keytab cleanup from old keys"""

import argparse
import logging
import os
import re
import shlex
import subprocess
import sys
import tempfile
import time
import urllib.parse


SUCCESS = 0
ERROR = 1
logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, stream=sys.stdout, format='%(levelname)s %(message)s')





def parse_args():
	"""parse arguments"""
	parser = argparse.ArgumentParser(usage="""
	TODO
""")
	parser.add_argument("--debug", action="store_true")
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





def cleanup(keytab, principal):
	"""fetch principal info from kdb, purge all non-corresponding keys from keytab"""

	logger.info("cleanup:: kdb get principal")
	_, _, realm = parse_principal(principal)
	kdb_kvno = None
	kdb_enctypes = []
	try:
		principal_listing = subprocess.check_output(shlex.split("kadmin.heimdal --local --realm=%s get %s" % (realm, principal))).decode("UTF-8")
		for line in principal_listing.splitlines():
			if line.strip().startswith("Kvno:"):
				kdb_kvno = int(line.strip().split(" ")[-1])

			if line.strip().startswith("Keytypes:"):
				for enctype in line.strip().split(":")[1].split(","):
					match = re.match(r"\s*(?P<enctype>.*)\((?P<salt>.*)\)\[(?P<kvno>\d+)\]", enctype)
					if match:
						kdb_enctypes.append(match.group("enctype"))
	except Exception as e:
		logger.error(e)
	if (not kdb_kvno) or (not kdb_enctypes):
		raise RuntimeError("fetching principal info from kdb failed")
	logger.debug("principal %s, kvno %d, enctypes %s", principal, kdb_kvno, kdb_enctypes)


	try:
		logger.info("cleanup:: prune keytab")
		keytab_listing = subprocess.check_output(shlex.split("ktutil --verbose --keytab=%s list" % keytab)).decode("UTF-8")
		for line in keytab_listing.splitlines():
			match = re.match(r"\s*(?P<kvno>\d+)\s+(?P<enctype>\S+)\s+(?P<principal>\S+)\s+(?P<date>\S+)\s*", line.strip())
			if match and (match.group("principal") == principal) and ((match.group("enctype") not in kdb_enctypes) or (int(match.group("kvno")) != kdb_kvno)):
				logger.info("removing: %s", line)
				subprocess.check_call(shlex.split( \
					"ktutil --keytab=%s remove --principal=%s --kvno=%s --enctype=%s" % (keytab, principal, int(match.group("kvno")), match.group("enctype"))))
	except Exception as e:
		logger.error(e)
		raise RuntimeError("pruning keytab failed") from None

	keytab_listing = subprocess.check_output(shlex.split("ktutil --verbose --keytab=%s list" % keytab)).decode("UTF-8")
	logger.debug("pruned keytab contents: %s", "\n".join(map(lambda x: "> "+x, keytab_listing.splitlines())))
	return True






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








def main():
	"""main"""
	args = parse_args()
	if args.debug:
		logger.setLevel(logging.DEBUG)
	logger.debug(args)
	_, _, _ = parse_principal(args.principal)

	try:
		keytab_temp = fetch(args.keytab)
		cleanup(keytab_temp, args.principal)
		put(keytab_temp, args.keytab, args.puppetstorage)
		os.unlink(keytab_temp)
	except Exception as e:
		logger.error(e)
		return ERROR

	logger.info("main:: finished")
	return SUCCESS



if __name__ == "__main__":
	sys.exit(main())
