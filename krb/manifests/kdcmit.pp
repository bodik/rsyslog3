# todo documentation
class krb::kdcmit(
	$avahi_broadcast = true,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")



	$kdc_server_real = $fqdn
	$packages = ["krb5-admin-server", "krb5-kdc"]
	if ( file_exists("/var/lib/krb5kdc/masterpassword") == 1 ) {
		$master_password = myexec("/bin/cat /var/lib/krb5kdc/masterpassword")
	} else {
		$master_password = generate_password()
	}

	file { "/etc/krb5.conf":
		content => template("${module_name}/etc/krb5.conf.erb"),
		owner => "root", group => "root", mode => "0644",
		before => Package[$packages],
	}
	file { "/etc/krb5kdc/":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
		before => Package[$packages],
	}
	file { "/etc/krb5kdc/kdc.conf":
		source => "puppet:///modules/${module_name}/etc/krb5kdc/kdc.conf",
		owner => "root", group => "root", mode => "0644",
		before => Package[$packages],
	}

	package { $packages: ensure => installed }
	exec { "init realm":
		command => "/bin/echo -e '${master_password}\n${master_password}' | /usr/sbin/krb5_newrealm",
		creates => "/var/lib/krb5kdc/principal.ok",
		require => Package[$packages],
	}

	include krb::kadminhttp

	class { "krb::avahikdc": enabled => $avahi_broadcast, }

}
