# Class for installing avahi utils and resolving daemon. This class is used
# during dynamic cloud autodiscovery by other classes.
#
# @example Usage
#  include metalib::avahi
#
class metalib::avahi() {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	package { ["avahi-daemon", "avahi-utils"]:
	        ensure => installed,
	}
	augeas { "/etc/avahi/avahi-daemon.conf":
                context => "/files/etc/avahi/avahi-daemon.conf",
                changes => [
			"set /files/etc/avahi/avahi-daemon.conf/server/use-ipv6 no",
			"set /files/etc/avahi/avahi-daemon.conf/publish/publish-aaaa-on-ipv4 no",
		],
		require => Package["avahi-daemon"],
		notify => Service["avahi-daemon"],
        }
	service { "avahi-daemon": 
		ensure => running, 
	}
}
