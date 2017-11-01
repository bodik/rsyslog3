#todo documentation
class krb::kdcheimdal(
	$avahi_broadcast = true,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")



	$kdc_server_real = $fqdn
	$packages = ["heimdal-kdc", "heimdal-clients"]
	package { $packages: ensure => installed }
	
	exec { "init realm":
		command => "/bin/echo -e '\n\n' | /usr/bin/kadmin.heimdal -l init RSYSLOG3",
		creates => "/var/lib/heimdal-kdc/heimdal.db",
		require => Package[$packages],
	}

	file { "/etc/krb5.conf":
		content => template("${module_name}/etc/krb5.conf.erb"),
		owner => "root", group => "root", mode => "0644",
		before => Package[$packages],
	}

	include krb::kadminhttp

	class { "krb::avahikdc": enabled => $avahi_broadcast, }
}
