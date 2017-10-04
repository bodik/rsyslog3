#!/usr/bin/python

import argparse
import json
import logging
import os
import shlex
import subprocess
import sys
import textwrap

logger = logging.getLogger()
logging.basicConfig(stream=sys.stderr, level=logging.WARN, format='%(asctime)-15s '+os.path.basename(sys.argv[0])+'[%(process)d] %(levelname)s %(message)s')


def get_tags(data, tag_name):
	return [i for i in data if i["tag_name"] == tag_name]



def render_parameters(data):
	if not data: return

	print "### Parameters\n"
	for tmp in data:
		print "**%s** -- %s\n" % (tmp["name"], tmp.get("text", "N/A"))

def render_return(data):
	if not data: return

	print "### Return\n"
	for tmp in data:
		print "%s\n" % tmp["text"]



def render_examples(data):
	if not data: return

	print "### Examples\n"
	for tmp in data:
		print "%s\n" % tmp["name"]
		print "```"
		print tmp["text"]
		print "```"


def render_other(data):
	if not data: return

	print json.dumps(data)



def render_item(chapter, item):
	logger.debug(json.dumps(item, indent=2))
	
	print "## %s: %s\n" % (chapter, item["name"])
	if item["docstring"]["text"]: print "%s\n" % item["docstring"]["text"]

	if "tags" in item["docstring"]:
		tags = list(set([i["tag_name"] for i in item["docstring"]["tags"]]))
		logger.debug("tags %s" % tags)

		render_parameters(get_tags(item["docstring"]["tags"], "param"))
		if "param" in tags: tags.remove("param")
		render_examples(get_tags(item["docstring"]["tags"], "example"))
		if "example" in tags: tags.remove("example")
		render_return(get_tags(item["docstring"]["tags"], "return"))
		if "return" in tags: tags.remove("return")
	
		for tag in tags:
			render_other(get_tags(item["docstring"]["tags"], tag))

	print ""



def load_data():
	return data

def parse_arguments():
        parser = argparse.ArgumentParser()
	parser.add_argument("--debug", action="store_true", help="debug output")
	parser.add_argument("--stdout", action="store_true", help="stdout output")
        args = parser.parse_args()
        return args


if __name__ == "__main__":
	cleanup_yardoc = True

        args = parse_arguments()
	if args.debug:
		logger.setLevel(logging.DEBUG)
	if not args.stdout:
		sys.stdout = open("README.md", 'w')

	if os.path.exists(".yardoc"):
		cleanup_yardoc = False
	
	# load data
	try:
		data = json.loads(subprocess.check_output(shlex.split("puppet strings generate --emit-json-stdout")))
	except:
		logger.warn("cannot generate code with puppet-strings; try `gem install puppet-strings`")
		data = {}
	logger.debug(json.dumps(data, indent=2))


	# render header
	fname = "README.header"
	if os.path.exists(fname):
		with open(fname,'r') as f:
			print f.read()

	# render all chapters: defined_types, puppet_functions, resource_types, puppet_classes
	for chapter in sorted(data.keys()):
		for item in data[chapter]:
			render_item(chapter, item)

	# render footer
	fname = "README.footer"
	if os.path.exists(fname):
		with open(fname,'r') as f:
			print f.read()

	# cleanup
	if cleanup_yardoc and os.path.exists(".yardoc"):
		subprocess.call(shlex.split("rm -r .yardoc"))

