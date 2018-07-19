#!/usr/bin/python3
"""perform principal rekey"""

import argparse
import logging
import os
import random
import shlex
import subprocess
import sys
import tempfile
import time
import urllib.parse


# ENCTYPES must [kadmin] default_keys= section in kadmin/krb config
ENCTYPES = ["des3-cbc-sha1", "aes256-cts-hmac-sha1-96"]
REKEY_CONFIG = "/etc/heimdal-kdc/kadmin-rekey.conf"

CHOICES = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$^&*()+/?,."
logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, stream=sys.stdout, format='%(levelname)s %(message)s')






def fetch(keytab):
	"""copy keytab to temporary file; returns name of the temp keytab"""

	keytab_url = urllib.parse.urlparse(keytab, scheme="file")
	with tempfile.NamedTemporaryFile(prefix="/dev/shm/rekey_heimdal_", delete=False) as ftmp:
		keytab_temp = ftmp.name
	logger.debug("keytab_temp: %s", keytab_temp)


	if keytab_url.scheme == "file":
		try:
			subprocess.check_call(shlex.split("cp --archive %s %s" % (keytab_url.path, keytab_temp)))
		except Exception:
			os.unlink(keytab_temp)
			raise RuntimeError("cannot fetch keytab") from None


	elif keytab_url.scheme == "ssh":
		try:
			subprocess.check_call(shlex.split("scp %s:%s %s" % (keytab_url.netloc, keytab_url.path, keytab_temp)))
		except Exception:
			os.unlink(keytab_temp)
			raise RuntimeError("cannot fetch keytab") from None


	else:
		os.unlink(keytab_temp)
		raise RuntimeError("invalid keytab specified")


	keytab_listing = subprocess.check_output(shlex.split("ktutil --verbose --keytab=%s list" % keytab_temp)).decode("UTF-8")
	logger.info("original keytab contents: %s", "\n".join(map(lambda x: "> "+x, keytab_listing.splitlines())))
	return keytab_temp






def generate_new_keys(keytab, principal, password_length):
	"""generates new keys for principal, returns new password"""

	## get current kvno
	kvno = None
	keytab_listing = subprocess.check_output(shlex.split("ktutil --verbose --keytab=%s list" % keytab)).decode("UTF-8")
	for line in reversed(keytab_listing.splitlines()):
		try:
			parsed_kvno, parsed_enctype, parsed_principal, parsed_date = list(filter(None, line.strip().split(" ")))
			logger.debug("%s %s %s %s", parsed_kvno, parsed_enctype, parsed_principal, parsed_date)
			if principal == parsed_principal:
				kvno = int(parsed_kvno)
				break
		except Exception:
			pass

	if not kvno:
		raise RuntimeError("cannot detect current kvno")
	logger.info("detected kvno: %s", kvno)


	## generate new password and put appropriate keys to keytab
	password = "".join([random.SystemRandom().choice(CHOICES) for _ in range(password_length)])
	try:
		for enctype in ENCTYPES:
			password_key = subprocess.check_output(shlex.split( \
				"string2key --principal=%s --keytype=%s %s" % (principal, enctype, password))).decode("UTF-8").split(" ")[-1]
			subprocess.check_call(shlex.split("ktutil --keytab=%s add --enctype=%s --principal=%s --kvno=%s --hex --password=%s" % ( \
				keytab, enctype, principal, kvno+1, password_key)))
	except Exception:
		raise RuntimeError("cannot add new key to keytab") from None


	keytab_listing = subprocess.check_output(shlex.split("ktutil --verbose --keytab=%s list" % keytab)).decode("UTF-8")
	logger.info("new keys keytab contents: %s", "\n".join(map(lambda x: "> "+x, keytab_listing.splitlines())))
	return password






def put(keytab_temp, keytab):
	"""update keytab with backup"""

	keytab_url = urllib.parse.urlparse(keytab, scheme="file")

	if keytab_url.scheme == "file":
		try:
			subprocess.check_call(shlex.split("cp --archive %s %s.rekeybackup.%s" % (keytab_url.path, keytab_url.path, time.time())))
			subprocess.check_call(shlex.split("cp --archive %s %s" % (keytab_temp, keytab_url.path)))
		except Exception:
			raise RuntimeError("cannot put keytab") from None


	elif keytab_url.scheme == "ssh":
                try:
                        subprocess.check_call(shlex.split("ssh %s 'cp --archive %s %s.rekeybackup.%s'" % (keytab_url.netloc, keytab_url.path, keytab_url.path, time.time())))
                        subprocess.check_call(shlex.split("scp %s %s:%s" % (keytab_temp, keytab_url.netloc, keytab_url.path)))
                except Exception:
                        raise RuntimeError("cannot put keytab") from None


	else:
		raise NotImplementedError


	return True






def kdb_cpw(principal, password):
	"""update principals password; override default_keys forcing new keys with requested enctypes"""

	try:
		subprocess.check_call(shlex.split("kadmin.heimdal --config-file=%s -l cpw --password=%s %s" % (REKEY_CONFIG, password, principal)))
	except Exception:
		raise RuntimeError("cannot cpw for principal") from None

	principal_listing = subprocess.check_output(shlex.split("kadmin.heimdal -l get %s" % principal)).decode("UTF-8")
	logger.info("updated principal: %s", "\n".join(map(lambda x: "> "+x, principal_listing.splitlines())))
	return True






def parse_args():
	"""parse arguments"""
	parser = argparse.ArgumentParser()
	parser.add_argument("--debug", action="store_true")
	parser.add_argument("--passwordlength", type=int, default=200)
	parser.add_argument("--keytab", required=True)
	parser.add_argument("--principal", required=True)
	return parser.parse_args()



def main():
	"""main"""
	args = parse_args()
	if args.debug:
		logger.setLevel(logging.DEBUG)
	logger.debug(args)

	try:
		keytab_temp = fetch(args.keytab)
		password = generate_new_keys(keytab_temp, args.principal, args.passwordlength)
		put(keytab_temp, args.keytab)
		kdb_cpw(args.principal, password)
		os.unlink(keytab_temp)
	except Exception as e:
		logger.error(e)



if __name__ == "__main__":
	sys.exit(main())
