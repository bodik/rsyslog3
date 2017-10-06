# Class will ensure installation of rsyslog packages from rsyslog metacentrum dev repository
#
class rsyslog::install {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	$installed_version = "8.24.0.r50"

	exec {"apt-get update": command => "/usr/bin/apt-get update", refreshonly => true, }
	file { "/etc/apt/sources.list.d/meta-rsyslog.list":
	        source => "puppet:///modules/rsyslog/etc/apt/sources.list.d/meta-rsyslog.list",
        	owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	file { "/etc/apt/apt.conf.d/99auth":       
		content => "APT::Get::AllowUnauthenticated yes;\n",
		owner => "root", group => "root", mode => "0644",
 	}

	package { "bc": ensure => installed, }
	package { ["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]:
		ensure => $installed_version,
		require => [File["/etc/apt/sources.list.d/meta-rsyslog.list"], File["/etc/apt/apt.conf.d/99auth"], Exec["apt-get update"]],
	}

	define config() {
		file { "${name}":
			content => template("${module_name}/${name}.erb"),
			owner => "root", group=> "root", mode=>"0644",
			require => Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"],
			notify => Service["rsyslog"],
		}
	}
}

