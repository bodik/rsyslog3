# Internal. Installs postfix as local MTA
class metalib::postfix() {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	package { "postfix": ensure => installed }
	service { "postfix": }

	file { "/etc/postfix/main.cf":
		content => template("${module_name}/etc/postfix/main.cf.erb"),
		owner => "root", group => "root", mode => "0644",
		notify => Service["postfix"],
		require => Package["postfix"],
	}
	
	file { "/etc/mailname":
		content => "${fqdn}\n",
		owner => "root", group => "root", mode => "0644",
	}
}

