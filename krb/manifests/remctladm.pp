# todo documentation
class krb::remctladm() {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")


	# install
	package { ["remctl-server", "remctl-client"]:
		ensure => installed
	}
	file { "/etc/remctl/conf.d/remctladm":
		content => "remctladmd ALL /puppet/krb/files/remctladm/remctladmd.py /etc/remctl/acl/remctladmd\n",
		owner => "root", group => "root", mode => "0640",
		require => Package["remctl-server"],
	}
	file { "/etc/remctl/acl/remctladmd":
		content => "anyuser:auth\n",
		owner => "root", group => "root", mode => "0640",
		require => Package["remctl-server"],
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
