# Class will install redis server and rediser -- tcp daemon which reads line
# separated messages from clients and pushes them into redis queue. Rediser
# will announce itself to others using avahi.
#
# @example Usage class { "rediser": }
#
class rediser(
	$service_user = "rediser",
	$avahi_broadcast = true,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")



	#redis
	package { "redis-server": ensure => installed, }
	service { "redis-server": ensure => running, }

	augeas { "/etc/redis/redis.conf" :
		lens => 'Spacevars.lns',
	        incl => "/etc/redis/redis.conf",
	        context => "/files/etc/redis/redis.conf",
	        changes => [
			"set port 16379",
			"set bind 0.0.0.0",
			"set maxmemory 1024000000",
			"rm save",
	        ],
	        require => Package["redis-server"],
       		notify => Service["redis-server"],
	}



	#rediser
	user { "$service_user":
		ensure => present, 
		system => true,
		home => "/var/run/rediser",
		managehome => false,
	}
	
	# we should install rsyslog rbXX version, default does not have pmnull parser
	include rsyslog::install
	package { "rsyslog-hiredis": ensure => "$rsyslog::install::installed_version" }

	file { "/etc/rediser.d":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "/etc/rediser.conf":
		source => "puppet:///modules/${module_name}/etc/rediser.conf",
		owner => "root", group => "root", mode => "0644",
		require => File["/etc/rediser.d"],
		notify => Service["rediser"],
	}

	rediser::config { "/etc/rediser.d/10-test.conf": }



	file { "/var/run/rediser":
		ensure => directory,
		owner => "${service_user}", group => "${service_user}", mode => "0755",
	}
	file { "/etc/systemd/system/rediser.service":
		content => template("${module_name}/rediser.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => [Package["rsyslog", "rsyslog-hiredis"], File["/etc/rediser.conf", "/var/run/rediser"]],
		notify => Service["rediser"],
	}
	service { "rediser":
		enable => true,
		ensure => running,
		require => [File["/etc/systemd/system/rediser.service"]],
	}



	# broadcast
	if($avahi_broadcast) {
		include metalib::avahi
		file { "/etc/avahi/services/rediser.service":
			content => template("${module_name}/etc/avahi/services/rediser.service.erb"),
			owner => "root", group => "root", mode => "0644",
			require => Package["avahi-daemon"],
			notify => Service["avahi-daemon"],
		}
	} else {
		file { "/etc/avahi/services/rediser.service": ensure => absent }
	}


	# defined resources
	define config() {
		file { "${name}":
			content => template("${module_name}/${name}.erb"),
			owner => "root", group=> "root", mode=>"0644",
			require => Package["rsyslog", "rsyslog-hiredis"],
			notify => Service["rediser"],
		}
	}
}
