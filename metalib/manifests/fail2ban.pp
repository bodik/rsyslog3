# Internal. Installs fail2ban with basic config (sshd)
class metalib::fail2ban() {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	package { "fail2ban": ensure => installed, }
	package { ["gamin","python-gamin","libgamin0"]: 
		ensure => purged,
		require => Package["fail2ban"],
	}
	service { "fail2ban":
		enable => true,
		ensure => running,
	}

	#ssh
	file {"/etc/fail2ban/jail.local":
		source => "puppet:///modules/${module_name}/etc/fail2ban/jail.local",
		owner => "root", group => "root", mode => "0644",
		require => Package["fail2ban"],
		notify => Service["fail2ban"]
	}
	#syslog
	file {"/etc/fail2ban/fail2ban.local":
		source => "puppet:///modules/${module_name}/etc/fail2ban/fail2ban.local",
		owner => "root", group => "root", mode => "0644",
		require => Package["fail2ban"],
		notify => Service["fail2ban"]
	}
}
