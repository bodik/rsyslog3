# todo documentation
class krb::avahikdc(
	$enabled = true,
) {
	if($enabled) {
		include metalib::avahi
		file { "/etc/avahi/services/kdc.service":
			content => template("${module_name}/etc/avahi/services/kdc.service.erb"),
			owner => "root", group => "root", mode => "0644",
			require => Package["avahi-daemon"],
			notify => Service["avahi-daemon"],
		}
	} else {
		file { "/etc/avahi/services/kdc.service": ensure => absent }
	}
}
