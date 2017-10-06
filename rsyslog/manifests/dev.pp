# Class will ensure installcompilation and debugging rsyslog8. Also disables
# stripping binaries for whole node because of generation debug enabled
# packages.
#
# @example Usage
#   include rsyslog::dev
#
class rsyslog::dev { 
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	# generic build deps
	package { ["dpkg-dev", "gcc", "make", "fakeroot", "git-buildpackage", "debhelper", "dh-autoreconf", "dh-systemd", "bison", "pkg-config", "dh-exec"]:
		ensure => installed,
	}

	# don't strip binaries without patching source code
	file { "/usr/bin/strip":
		ensure => link,	target => "/bin/true",
	}

	# version specific deps
	package { 
		[ "zlib1g-dev", "default-libmysqlclient-dev", "libpq-dev", "libmongo-client-dev", "libcurl4-gnutls-dev", 
		  "libkrb5-dev", "librelp-dev", "libestr-dev", "libee-dev", "liblognorm-dev", 
		  "liblogging-stdlog-dev", "libjson-c-dev", "uuid-dev", "libgcrypt-dev", "flex", "libgnutls28-dev",
		  "librdkafka-dev", "libsystemd-dev", "libhiredis-dev", "libczmq-dev",
		  "faketime",
		]:
		ensure => installed,
	}
}
