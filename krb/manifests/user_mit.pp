class krb::user_mit(
	$kdc_server = undef,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")



	if ( $kdc_server ) {
		$kdc_server_real = $kdc_server
	} else {
		$kdc_server_real = avahi_findservice("_krb5kdc._udp")
	}


	file { "/etc/krb5.conf":
		content => template("${module_name}/etc/krb5.conf.erb"),
		owner => "root", group => "root", mode => "0644",
	}
	package { "krb5-user": ensure => installed, }


	exec { "getkeytab":
		command => "/bin/sh /puppet/krb/bin/getkeytab.sh",
		creates => "/etc/krb5.keytab",
	}
}
