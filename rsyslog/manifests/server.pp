# Class will ensure installation of rsyslog packages and configures daemon to server mode eg. :
# - imtcp, imrelp, optionally imgssapi on krb5 enabled nodes
# - stores all incoming logs into IP based directory stucture
# - optionaly forwards all gathered logs to rediser for analytics (omfwd).
# - announce self to others using avahi.
#
# @example install, perform autodiscovery and forward logs to rediser
#   include rsyslog::server
#
# @example install, forwardm logs to designated analytics node
#   class { "rsyslog::server": rediser_server => "1.2.3.4", }
#
# @example install and do not forward gathered log anywhere
#   class { "rsyslog::server": rediser_auto => false, }
#
# @param rediser_server hostname or ip to forward all logs to for analytics, has precedence over rediser_auto
# @rediser_auto perform rediser autodiscovery by avahi
class rsyslog::server ( 
	$perhost = false,
	$pertime = true,

	$rediser_server = undef,
	$rediser_auto = true,

	$avahi_broadcast = true,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	class { "rsyslog::install": }
	service { "rsyslog": ensure => running, }

        notice("server services ACTIVE")
	rsyslog::install::config { [
		"/etc/rsyslog.d/00-server-globals.conf",
		
		"/etc/rsyslog.d/05-input-imudp.conf",
		"/etc/rsyslog.d/05-input-imtcp.conf",
		"/etc/rsyslog.d/05-input-imrelp.conf",

		"/etc/rsyslog.d/10-log-service-auth.conf",
		"/etc/rsyslog.d/10-log-service-modules.conf",
		"/etc/rsyslog.d/10-log-service-pbs.conf",

		"/etc/rsyslog.d/zz_stopnonlocalhost.conf"
		]:
	}

	if ($perhost) { rsyslog::install::config { "/etc/rsyslog.d/10-log-perhost.conf": } }
	if ($pertime) { rsyslog::install::config { "/etc/rsyslog.d/10-log-pertime.conf": } }

	if file_exists ("/etc/krb5.keytab") == 1 {
		rsyslog::install::config { "/etc/rsyslog.d/05-input-imgssapi.conf": }
	        notice("imgssapi ACTIVE")
	} else {
		notice("imgssapi PASSIVE")
	}



	if ($rediser_server) {
		$rediser_server_real = $rediser_server
	} elsif ( $rediser_auto == true ) {
		$rediser_server_real = avahi_findservice("_rediser._tcp")
	}

	if ( $rediser_server_real ) {
		file { "/etc/rsyslog.d/20-forwarder-rediser-syslog.conf":
			content => template("${module_name}/etc/rsyslog.d/20-forwarder-rediser-syslog.conf.erb"),
			owner => "root", group=> "root", mode=>"0644",
			require => Class["rsyslog::install"],
			notify => Service["rsyslog"],
		}
	        notice("forward rediser ACTIVE")
	} else {
		file { "/etc/rsyslog.d/20-forwarder-rediser-syslog.conf": ensure => absent, }
		file { "/etc/rsyslog.d/21-forwarder-rediser-auth.conf": ensure => absent, }
		notice("forward rediser PASSIVE")
	}



	# tcpkill tests
	package { ["libpcap0.8", "libnet1"]:
		ensure => installed,
	}

	# autoconfig
	if($avahi_broadcast) {
		include metalib::avahi
		file { "/etc/avahi/services/sysel.service":
			content => template("${module_name}/etc/avahi/services/sysel.service.erb"),
			owner => "root", group => "root", mode => "0644",
			require => Package["avahi-daemon"], #tady ma byt class ale tvori kruhovou zavislost
			notify => Service["avahi-daemon"],
		}
	} else {
		file { "/etc/avahi/services/sysel.service": ensure => absent }
	}
}
