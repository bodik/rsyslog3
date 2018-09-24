#!/usr/bin/env python3

import argparse
import json
import logging
import shlex
import socket
import subprocess

logger = logging.getLogger()
logging.basicConfig(level=logging.INFO, format='%(levelname)s %(message)s')



def resolve_address(address):
	try:
		(hostname, aliaslist, ipaddrlist) = socket.gethostbyaddr(address)
		return hostname
	except Exception:
		return address



def get_connections():
	ret = []
	self_address = subprocess.getoutput("facter ipaddress")
	netstat = subprocess.getoutput("netstat -nlpa | grep ^tcp | grep ESTABLISHED")
	for line in netstat.splitlines():
		tmp = line.split()
		local_addr = tmp[3]
		remote_addr = tmp[4]
		if local_addr == "%s:515" % self_address:
			ret.append(resolve_address(remote_addr.split(":")[0]))
	logger.debug(ret)
	return ret



def get_duplicate_connections(connections):
	ret = {}
	for i in set(connections):
		count = connections.count(i)
		if count > 1:
                	ret[i] = count
	logger.debug(ret)
	return ret



def get_pbsnodes():
	ret = []
	pbsnodes_output = subprocess.getoutput("pbsnodes -a -F dsv")
	for line in pbsnodes_output.splitlines():
		tmp = line.split("|")
		mom = tmp[1].split("=")[1]
		state = tmp[3].split("=")[1].split(",")
		if "down" not in state:
			ret.append(mom)
	logger.debug(ret)
	return ret



### MAIN

parser = argparse.ArgumentParser()
parser.add_argument("--debug", action="store_true")
args = parser.parse_args()
if args.debug:
	logger.setLevel(logging.DEBUG)


connections = get_connections()
duplicate_connections = get_duplicate_connections(connections)
pbsnodes = get_pbsnodes()
missing_pbsnodes = [x for x in pbsnodes if x not in connections]
connected_nonpbs_nodes = [x for x in connections if x not in pbsnodes]

print("Total connections: %d" % len(connections))
print("Duplicate connections: %s" % duplicate_connections)
print("Total pbsnodes: %d" % len(pbsnodes))
print("Missing pbsnodes: %s" % missing_pbsnodes)
