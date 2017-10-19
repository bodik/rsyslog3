#!/usr/bin/python

import os
import socket
import sys
sys.dont_write_bytecode = True
sys.path.append('/puppet/krb5/bin/')
import remctladmd


if __name__ == "__main__":
	args = remctladmd.parse_arguments()

	if (args.command == "aaa"):
		print "abc"
	else:
		cmd = ["/usr/bin/remctl", "-d", "-b", "127.0.0.1", socket.getfqdn(), "remctladmd"] + sys.argv[1:]
		os.execve(cmd[0], cmd, os.environ)

