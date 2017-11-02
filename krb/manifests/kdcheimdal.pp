#todo documentation
class krb::kdcheimdal(
	$avahi_broadcast = true,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")



	$kdc_server_real = $fqdn
	file { "/etc/krb5.conf":
		content => template("${module_name}/etc/krb5.conf.erb"),
		owner => "root", group => "root", mode => "0644",
		before => Package["heimdal-clients"],
	}

	package { "heimdal-clients": ensure => installed }
	package { "heimdal-kdc":
		ensure => installed,
		require => Package["heimdal-clients"]
	}

	exec { "init realm":
		command => "/bin/echo -e '\n\n' | /usr/bin/kadmin.heimdal -l init RSYSLOG3",
		unless => "/usr/bin/kadmin.heimdal -l list -l krbtgt/RSYSLOG3@RSYSLOG3",
		require => Package["heimdal-kdc"],
	}

	file { "/var/lib/heimdal-kdc/kadmind.acl":
		ensure => link, target => "/etc/heimdal.kdc/kadmind.acl",
		require => Package["heimdal-kdc"],
	}


	include krb::kadminhttp
	class { "krb::avahikdc": enabled => $avahi_broadcast, }
}
