# todo documentation
class krb::user(
	$kdc_server = undef,
	$impl = undef,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")



	if ( $kdc_server ) {
		$kdc_server_real = $kdc_server
	} else {
		$kdc_server_real = avahi_findservice("_kdc._udp")
	}
	file { "/etc/krb5.conf":
		content => template("${module_name}/etc/krb5.conf.erb"),
		owner => "root", group => "root", mode => "0644",
	}

	if ( $impl ) {
		$impl_real = $impl
	} else {
		if ( file_exists("/usr/share/doc/krb5-user/copyright") == 1 ) {
			$impl_real = "mit"
		} elsif ( file_exists("/usr/share/doc/heimdal-clients/copyright") == 1 ) {
			$impl_real = "heimdal"
		} else {
			$impl_real = "mit"
		}
	}

	case $impl_real {
		"mit": { package { "krb5-user": ensure => installed, } }
		"heimdal": { package { "heimdal-clients": ensure => installed, } }
	}


	exec { "kadminhttp_getkeytab.sh":
		command => "/bin/sh /puppet/krb/bin/kadminhttp_getkeytab.sh",
		creates => "/etc/krb5.keytab",
	}
}
