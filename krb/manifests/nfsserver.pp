#TODO: documentation
class krb::nfsserver() {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	
	package { ["nfs-common", "nfs-kernel-server"]: ensure => installed }

	file { "/nfsroot":
		ensure => directory,
		owner => "root", group => "root", mode => "0644",
	}

	exec { "exportfs":
		command => "/usr/sbin/exportfs -ra",
		refreshonly => true,
		require => Package["nfs-kernel-server"],
	}

	file { "/etc/exports":
		content => "/nfsroot *(sec=krb5:krb5i:krb5p,rw,async,fsid=0,no_subtree_check,root_squash)",
		owner => "root", group => "root", mode => "0644",
		notify => Exec["exportfs"],
	}
}
