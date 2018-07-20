#todo documentation
class krb::kdcheimdal(
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
		command => "/bin/echo -e '\n\n' | /usr/bin/kadmin.heimdal --local init RSYSLOG3; /usr/bin/kadmin.heimdal --local ank --user-defaults --random-key testroot@RSYSLOG3",
		unless => "/usr/bin/kadmin.heimdal --local list -l krbtgt/RSYSLOG3@RSYSLOG3",
		require => Package["heimdal-kdc"],
	}

	file { "/var/lib/heimdal-kdc/kadmind.acl":
		ensure => link, target => "/etc/heimdal.kdc/kadmind.acl",
		require => Package["heimdal-kdc"],
	}


	include krb::kadminhttp
	class { "krb::avahikdc": enabled => $avahi_broadcast, }


	# rekey support
	package { "krb5-gss-samples": ensure => installed }
	file { "/etc/heimdal-kdc/kadmin-weakcrypto.conf":
		content => template("${module_name}/etc/heimdal-kdc/kadmin-weakcrypto.conf.erb"),
		owner => root, group => "root", mode => "0644",
	}
	file { "/etc/heimdal-kdc/kadmin-rekey.conf":
		content => template("${module_name}/etc/heimdal-kdc/kadmin-rekey.conf.erb"),
		owner => root, group => "root", mode => "0644",
	}
}
