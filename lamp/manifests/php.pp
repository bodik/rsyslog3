# Internal. Installs php module for apache2 webserver, installs basic test scripts and dashboard
#
class lamp::php() {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	#deps
	ensure_resource( 'service', "apache2", {} )
	ensure_resource( 'file', "/var/www/server", {} )

	package { [ "libapache2-mod-php", "php-curl", "php-imap", "php-sqlite3", "php-pear", "php-gd", "php-mysql", "php-mcrypt" ]: 
		ensure => installed,
	}


	file { "/etc/php/7.0/apache2/php.ini":
		source => "puppet:///modules/${module_name}/etc/php/7.0/apache2/php.ini",
		require => Package["libapache2-mod-php"],
		notify => Service["apache2"],
	}
	file { "/etc/apache2/php.ini":
		ensure => link, target => "../php/7.0/apache2/php.ini",
		require => File["/etc/php/7.0/apache2/php.ini"]
	}

	#php++ testy
	file { "/var/www/server/rsyslog3":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
		require => File["/var/www/server"],
	}
	file { "/var/www/server/rsyslog3/test":
		source => "puppet:///modules/${module_name}/var/www/server/rsyslog3/test",
		recurse => true,
		owner => "root", group => "root", mode => "0644",
		require => File["/var/www/server/rsyslog3"],
	}

}
