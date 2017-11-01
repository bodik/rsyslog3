# todo documentation
class krb::kadminhttp() {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	package { "python-netifaces": ensure => installed, }
	file { "/opt/kadminhttp":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "/opt/kadminhttp/kadminhttp.py":
		source => "puppet:///modules/${module_name}/kadminhttp.py",
		owner => "root", group => "root", mode => "0755",
		require => Package["python-netifaces"],
		notify => Service["kadminhttp"],
	}
	file { "/etc/systemd/system/kadminhttp.service":
		content => template("${module_name}/kadminhttp.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["/opt/kadminhttp/kadminhttp.py"],
		notify => Service["kadminhttp"],
	}
	service { "kadminhttp":
		enable => true,
		ensure => running,
		require => File["/etc/systemd/system/kadminhttp.service"],
	}
}
