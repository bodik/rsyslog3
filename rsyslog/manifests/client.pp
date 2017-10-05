# Class will ensure installation of rsyslog packages and configures daemon to client mode eg. : 
# - forwards all logs to rsyslog server using omrelp or omgssapi on krb5 enabled nodes
#
# @example install default version, perform autodiscovery and forward logs to rsyslog server
#   include rsyslog::client
#
# @example install, forwardm logs to designated server node
#   class { "rsyslog::client": 
#     rsyslog_server => "1.2.3.4", 
#   }
#
# @example install rsyslog client and do not forward gathered log anywhere
#   class { "rsyslog::server": 
#     rsyslog_auto => false, 
#   }
#
# @param rsyslog_server hostname or ip to forward all logs to (default undef)
# @param rsyslog_server_auto perform rsyslog server autodiscovery by avahi (defult true)
# @param rsyslog_server_service name of rsyslog server service to discover (default "_syselgss._tcp")
class rsyslog::client (
	$rsyslog_server = undef,
	$rsyslog_server_auto = true,
	$rsyslog_server_service = "_syselgss._tcp",
) {
	class { "rsyslog::install": }
	service { "rsyslog": ensure => running, }



	if ( $rediser_server ) {
		$rsyslog_server_real = $rsyslog_server
	} elsif ( $rsyslog_server_auto == true ) {
		include metalib::avahi
		$rsyslog_server_real = avahi_findservice($rsyslog_server_service)
		notice("rsyslog_server_real discovered as ${rsyslog_server_real}")
	}

	if ( $rsyslog_server_real ) {
		if file_exists ("/etc/krb5.keytab") == 0 {
			$forward_template = "${module_name}/etc/rsyslog.d/meta-remote-omrelp.conf.erb"
		} else {
			$forward_template = "${module_name}/etc/rsyslog.d/meta-remote-omgssapi.conf.erb"
		}
		file { "/etc/rsyslog.d/meta-remote.conf":
			content => template($forward_template),
			owner => "root", group=> "root", mode=>"0644",
			require => Class["rsyslog::install"],
			notify => Service["rsyslog"],
		}
	        notice("forward ACTIVE")
	} else {
		file { "/etc/rsyslog.d/meta-remote.conf":
			ensure => absent,
		}
	        notice("forward PASSIVE")
	}
}

