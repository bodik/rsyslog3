# todo documentation
class krb::remctladm() {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")


	# install
	package { ["remctl-server", "remctl-client"]:
		ensure => installed
	}

	service { "inetd": }
	file_line { "remove inetd remctl conf":
		ensure => absent,
		path => "/etc/inetd.conf", line => "/usr/sbin/remctld", match => "/usr/sbin/remctld",
		match_for_absence => true,
		notify => Service["inetd"],
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



	# client
	file { "/etc/remctl/conf.d/remctladm":
		content => "remctladmd ALL /puppet/krb/files/remctladm/remctladmd.py /etc/remctl/acl/remctladmd\n",
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
	file { "/usr/local/bin/remctladm":
		ensure => link, target => "/puppet/krb/files/remctladm/remctladm.py",
	}


	if( file_exists("/etc/krb5kdc/kadm5.acl") == 1 ) {
		file_line { "main manager principal":
			path => "/etc/krb5kdc/kadm5.acl",
			line => "host/${fqdn} acdeilmps",
			notify => Service["krb5-admin-server"],
		}
		service { "krb5-admin-server": }
	}

	if( file_exists("/etc/heimdal-kdc/kadmind.acl") == 1 ) {
		file_line { "main manager principal":
			path => "/etc/heimdal-kdc/kadmind.acl",
			line => "host/${fqdn} cpw,list,delete,modify,add,get,get-keys",
		}
	}

}
