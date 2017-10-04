# Manages basic installation and config of apache2 webserver, configures
# status, dir, default virtualhost, prefork config, ...
#
# @example Usage
#   include lamp::apache2
#
class lamp::apache2() {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")



	#install apache
	package { ["apache2"]: 
		ensure => installed,
	}
	service { "apache2":
		ensure => running,
		enable => true,
	}


	# ensure basic 
	file { ["/etc/apache2/sites-enabled/000-default", "/etc/apache2/sites-enabled/000-default.conf", "/var/www/html"]:
		ensure => absent,
		require => Package["apache2"],
		notify => Service["apache2"],
	}
	file { "/etc/apache2/ssl":
		ensure => directory,
		owner => "root", group => "root", mode => "0750",
		require => Package["apache2"]
	}
	
	#some typical setting
	ensure_resource( 'lamp::apache2::a2dismod', "cgi", {} )
	ensure_resource( 'lamp::apache2::a2enmod', "headers", {} )
	ensure_resource( 'lamp::apache2::a2enmod', "rewrite", {} )
	ensure_resource( 'lamp::apache2::a2enmod', "expires", {} )
	ensure_resource( 'lamp::apache2::a2enmod', "socache_shmcb", {} )
	ensure_resource( 'lamp::apache2::a2enmod', "ssl", {} )

	ensure_resource( 'lamp::apache2::a2enmod', "status", {} )
	file { "/etc/apache2/mods-available/status.conf":
		source => "puppet:///modules/${module_name}/etc/apache2/mods-available/status.conf",
		owner => "root", group => "root", mode => "0644",
		require => Package["apache2"],
		notify => Service["apache2"],
	}

	ensure_resource( 'lamp::apache2::a2enmod', "dir", {} )
	file { "/etc/apache2/mods-available/dir.conf":
		source => "puppet:///modules/${module_name}/etc/apache2/mods-available/dir.conf",
		owner => "root", group => "root", mode => "0644",
		require => Package["apache2"],
		notify => Service["apache2"],
	}

	ensure_resource( 'lamp::apache2::a2disconf', "serve-cgi-bin", {} )
	ensure_resource( 'lamp::apache2::a2disconf', "javascript-common", {} )

	# signatury, sameorigin
	ensure_resource( 'lamp::apache2::a2enconf', "z99_miscsec", { "require" => File["/etc/apache2/conf-available/z99_miscsec.conf"] } )
	file { "/etc/apache2/conf-available/z99_miscsec.conf":
		source => "puppet:///modules/${module_name}/etc/apache2/conf-available/z99_miscsec.conf",
		owner => "root", group => "root", mode => "0644",
		require => Package["apache2"],
		notify => Service["apache2"],
	}

        ensure_resource( 'lamp::apache2::a2dismod', "mpm_event", {} )
        ensure_resource( 'lamp::apache2::a2enmod', "mpm_prefork", { "require" => Lamp::Apache2::A2dismod["mpm_event"]} )
	file { "/etc/apache2/mods-available/mpm_prefork.conf":
		source => [
				"puppet:///modules/${module_name}/etc/apache2/mods-available/mpm_prefork.conf.${fqdn}",
				"puppet:///modules/${module_name}/etc/apache2/mods-available/mpm_prefork.conf",
			  ],
		owner => "root", group => "root", mode => "0644",
		require => Package["apache2"],
		notify => Service["apache2"],
	}




	#basic virtualhosts
	file { "/etc/apache2/sites-enabled/00server.conf":
		content => template("${module_name}/etc/apache2/sites-enabled/00server.conf.erb"),
		owner => "root", group => "root", mode => "0644",
		require => Package["apache2"],
		notify => Service["apache2"],
	}
	file { "/var/www/server":
	        ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "/var/www/server/index.html":
		content => "HaaS cesnet.cz -- Unauthorized access to this device is prohibited",
		owner => "root", group => "root", mode => "0644",
	}
	exec { "install_sslselfcert.sh":
		command => "/bin/sh /puppet/metalib/bin/install_sslselfcert.sh /etc/apache2/ssl/",
		creates => "/etc/apache2/ssl/${fqdn}.crt",
		require => File["/etc/apache2/ssl"],
	}
	file { "/etc/apache2/ssl/default.key":
		ensure => link, target => "/etc/apache2/ssl/${fqdn}.key", replace => false,
		require => Exec["install_sslselfcert.sh"],
	}
	file { "/etc/apache2/ssl/default.crt":
		ensure => link, target => "/etc/apache2/ssl/${fqdn}.crt", replace => false,
		require => Exec["install_sslselfcert.sh"],
	}

	class { "lamp::php": }


	# defined resources

	# Internal. Enables apache2 module
	define a2enmod() { exec { "a2enmod $name":
			command => "/usr/sbin/a2enmod $name", unless => "/usr/sbin/a2query -m $name",
			require => Package["apache2"], notify => Service["apache2"],
	} }

	# Internal. Disables apache2 module
	define a2dismod() { exec { "a2dismod $name":
	                command => "/usr/sbin/a2dismod $name", onlyif => "/usr/sbin/a2query -m $name",
			require => Package["apache2"], notify => Service["apache2"],
	} }

	# Internal. Enables apache2 config
	define a2enconf() { exec { "a2enconf $name":
	                command => "/usr/sbin/a2enconf $name", unless => "/usr/sbin/a2query -c $name",
			require => Package["apache2"], notify => Service["apache2"],
        } }

	# Internal. Disables apache2 config
	define a2disconf() { exec { "a2disconf $name":
	                command => "/usr/sbin/a2disconf $name", onlyif => "/usr/sbin/a2query -c $name",
			require => Package["apache2"], notify => Service["apache2"],
        } }

}
