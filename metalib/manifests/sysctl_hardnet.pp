# Internal. Hardens networking on linux box.
class metalib::sysctl_hardnet {
	file { "/etc/sysctl.d/hardnet.conf":
		content => template("${module_name}/etc/sysctl.d/hardnet.conf.erb"),
		owner => "root", group => "root", mode => "0644",
	}
	# enforcement is not really working since machine can be configured before puppet comes throug
	# so at least one post install reboot might be needed to fully apply the setting
	exec { "force setting":
		command => "/sbin/sysctl --load=/etc/sysctl.d/hardnet.conf",
		unless => "/sbin/sysctl -a | /bin/grep 'net.ipv6.conf.all.accept_ra = 0'",
		require => File["/etc/sysctl.d/hardnet.conf"],
	}
}
