#!/usr/bin/python

import argparse
import base64
import logging
import os
import socket
import subprocess
import sys

logger = logging.getLogger()
logging.basicConfig(level=logging.DEBUG, format='%(asctime)-15s '+os.path.basename(sys.argv[0])+'[%(process)d] %(levelname)s %(message)s')






def remctlcall(cmd):
	cmd = ["/usr/bin/remctl", args.server, "remctladmd"] + cmd
	proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	(proc_stdout, proc_stderr) = proc.communicate()
	return (proc, proc_stdout, proc_stderr)



def parse_arguments():
	parser = argparse.ArgumentParser()
	parser.add_argument("--server", default=socket.getfqdn(), help="remctladmd server")

	subparsers = parser.add_subparsers(dest='command')

	parser_createkeytab = subparsers.add_parser("createkeytab", help="createkeytab command help")
	parser_createkeytab.add_argument("--host", required=True, help="create (upsert principals) keytab for hostname")
	parser_createkeytab.add_argument("--services", required=True, nargs="+", help="create (upsert principals) keytab for services at hostname")
	parser_createkeytab.add_argument("--outfile", required=True, help="write created keytab to file")

	parser_storesshhostkey = subparsers.add_parser("storesshhostkey", help="storesshhostkey command help")
	parser_storesshhostkey.add_argument("--host", required=True, help="hostname to store key for")
	parser_storesshhostkey.add_argument("--filename", required=True, help="filepath")

	parser_getsshhostkey = subparsers.add_parser("getsshhostkey", help="getsshhostkey command help")
	parser_getsshhostkey.add_argument("--host", required=True, help="get file for hostname")
	parser_getsshhostkey.add_argument("--filename", required=True, help="filename to get from storage")
	parser_getsshhostkey.add_argument("--outfile", required=True, help="write fetched file to path")


        # finish parsing        
        args = parser.parse_args()
        return args



if __name__ == "__main__":
	args = parse_arguments()



	if (args.command == "createkeytab"):
		cmd = ["createkeytab", "--host", args.host, "--services"] + args.services
		(proc, proc_stdout, proc_stderr) = remctlcall(cmd)
		sys.stderr.write(proc_stderr)

		# data of created keytab are transfered via stdout encoded in base64
		with open(args.outfile, "w") as f:
			f.write(base64.b64decode(proc_stdout))
		if (proc.returncode == 0):
			logger.debug("keytab for %s created in %s" % (args.host, args.outfile))



	if (args.command == "storesshhostkey"):
		# getconf ARG_MAX, xargs --show-limits, base64 encoding
		if (os.stat(args.filename).st_size > 98000):
			raise Exception("file too big for remctl transfer")
		with open(args.filename, "r") as f:
			data = base64.b64encode(f.read())

		cmd = ["storesshhostkey", "--host", args.host, "--filename", os.path.basename(args.filename), "--data", data]
		(proc, proc_stdout, proc_stderr) = remctlcall(cmd)
		sys.stderr.write(proc_stderr)
		sys.stdout.write(proc_stdout)



	if (args.command == "getsshhostkey"):
		cmd = ["getsshhostkey", "--host", args.host, "--filename", args.filename]
		(proc, proc_stdout, proc_stderr) = remctlcall(cmd)
		sys.stderr.write(proc_stderr)

		# data of keyfile are transfered via stdout encoded in base64
		with open(args.outfile, "w") as f:
			f.write(base64.b64decode(proc_stdout))
		if (proc.returncode == 0):
			logger.debug("file %s for %s created in %s" % (args.filename, args.host, args.outfile))


	sys.exit(proc.returncode)

