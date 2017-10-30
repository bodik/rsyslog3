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


	package { "python-netifaces": ensure => installed, }
	file { "/opt/kdc_http":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "/opt/kdc_http/kdc_http.py":
		source => "puppet:///modules/${module_name}/kdc_http.py",
		owner => "root", group => "root", mode => "0755",
		require => [Package[$packages], Package["python-netifaces"]],
		notify => Service["kdc_http"],
	}
	file { "/etc/systemd/system/kdc_http.service":
		content => template("${module_name}/kdc_http.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["/opt/kdc_http/kdc_http.py"],
		notify => Service["kdc_http"],
	}
	service { "kdc_http":
		enable => true,
		ensure => running,
		require => [File["/etc/systemd/system/kdc_http.service"]],
	}



	# broadcast
	if($avahi_broadcast) {
		include metalib::avahi
		file { "/etc/avahi/services/krb5kdc.service":
			content => template("${module_name}/etc/avahi/services/krb5kdc.service.erb"),
			owner => "root", group => "root", mode => "0644",
			require => Package["avahi-daemon"],
			notify => Service["avahi-daemon"],
		}
	} else {
		file { "/etc/avahi/services/krb5kdc.service": ensure => absent }
	}

}
