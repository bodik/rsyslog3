# Internal. Cleans up /var/lib/puppet from old files and reports
class metalib::puppet_cleanup() {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	tidy { "/var/cache/puppet/clientbucket":
		age => "12w",
		recurse => true,
		type => "ctime",
		rmdirs => true,
	}
	tidy { "/var/cache/puppet/reports":
		age => "12w",
		recurse => true,
		type => "ctime",
		rmdirs => true,
	}
}
