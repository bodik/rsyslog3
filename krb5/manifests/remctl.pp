class krb5::remctl() {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")


	package { ["remctl-server", "remctl-client"]:
		ensure => installed
	}
	package { "openbsd-inetd":
		ensure => absent,
		require => Package["remctl-server"],
		before => Service["remctld"],
	}
	file_line { "remove inetd remctl conf":
		ensure => absent,
		path => "/etc/inetd.conf",
		line => "/usr/sbin/remctld",
		match => "/usr/sbin/remctld",
		match_for_absence => true,
	}
	file { "/etc/remctl/conf.d/remctladm":
		content => "remctladmd ALL /puppet/krb5/bin/remctladmd.py /etc/remctl/acl/remctladmd\n",
		owner => "root", group => "root", mode => "0640",
		require => Package["remctl-server"],
		notify => Service["remctld"],
	}
	file { "/etc/remctl/acl/remctladmd":
		content => "host/$fqdn@RSYSLOG3\n",
		owner => "root", group => "root", mode => "0640",
		require => Package["remctl-server"],
		notify => Service["remctld"],
	}

	file { "/etc/systemd/system/remctld.service": 
		source => "puppet:///modules/${module_name}/etc/systemd/system/remctld.service",
		owner => "root", group => "root", mode => "0644",
		require => Package["remctl-server"],
	}
	service { "remctld":
		ensure => running,
		enable => true,
		require => File["/etc/systemd/system/remctld.service"],
	}



	file { "/usr/local/bin/remctladm":
		ensure => link, target => "/puppet/krb5/bin/remctladm.py",
	}

}
