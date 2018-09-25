#todo documentation
class krb::kdcheimdal(
	$realm = "RSYSLOG3",
	$avahi_broadcast = true,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	# deps
	ensure_resource("service", "heimdal-kdc", {})



	$kdc_server_real = $fqdn
	file { "/etc/krb5.conf":
		content => template("${module_name}/etc/krb5.conf.erb"),
		owner => "root", group => "root", mode => "0644",
		before => Package["heimdal-clients"],
	}
	file { "/etc/heimdal-kdc/kdc.conf":
		source => "puppet:///modules/${module_name}/etc/heimdal-kdc/kdc.conf",
		owner => "root", group => "root", mode => "0644",
		require => Package["heimdal-kdc"],
		notify => Service["heimdal-kdc"],
	}


	package { "heimdal-clients": ensure => installed }
	package { "heimdal-kdc":
		ensure => installed,
		require => Package["heimdal-clients"]
	}

	exec { "init realm":
		command => "/bin/echo -e '\n\n' | /usr/bin/kadmin.heimdal --local init ${realm}; /usr/bin/kadmin.heimdal --local ank --use-defaults --random-key testroot@${realm}",
		unless => "/usr/bin/kadmin.heimdal --local list -l krbtgt/${realm}@${realm}",
		require => Package["heimdal-kdc"],
	}

	file { "/var/lib/heimdal-kdc/kadmind.acl":
		ensure => link, target => "/etc/heimdal.kdc/kadmind.acl",
		require => Package["heimdal-kdc"],
	}


	class { "krb::kadminhttp": realm => $realm, }
	class { "krb::avahikdc": enabled => $avahi_broadcast, }
}
