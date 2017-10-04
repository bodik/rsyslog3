# Class manages basic set of setting and packages which should/should not be
# present on every/new node. 
#
# @example Usage
#   include metalib::base
#
class metalib::base() {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	# globals
	class { "metalib::fail2ban":
		require => Package["linux-image-amd64"],
	}
	class { "metalib::postfix": }
	class { "metalib::sysctl_hardnet": }
	class { "metalib::wget": }



	# base
	package { [
		"nfs-common", "rpcbind", "amd64-microcode", "intel-microcode", 
		"joe", "nano", "pico"]: 
		ensure => purged
	}
	package { [
		"rsyslog", "openssh-server", "locales", "ntp", "ntpdate", "firmware-linux-free", "firmware-linux-nonfree", "linux-image-amd64", "file", "rsync", "gnupg", "dirmngr", "libpam-systemd",
		"mc","vim","nagios-plugins-basic", "telnet", "links", "bash-completion", "dos2unix", "screen", "p7zip-full", "bzip2", "atop", "iotop", "curl", "netcat", "parallel"]: 
		ensure => installed,
		require => [File["/etc/apt/sources.list"], Exec["apt-get update"]],
	}
	package { "puppet-strings":
		ensure => installed,
		provider => gem,
	}


	file { "/etc/apt/sources.list":
		source => [
			"puppet:///modules/${module_name}/etc/apt/sources.list.${lsbdistcodename}",
			#docker stretch missing lsbcoderelease fact
			"puppet:///modules/${module_name}/etc/apt/sources.list.stretch"
			],
		owner => "root", group => "root", mode => "0644",
		notify => Exec["apt-get update"],
	}
	exec { "apt-get update":
		command => "/usr/bin/apt-get update",
		refreshonly => true,
	}
	cron { "apt":
                command => "/usr/bin/apt-get update 1>/dev/null",
                user => root, hour => 0, minute => 0,
        }



	file { "/etc/hostname":
		content => "${hostname}\n",
		owner => "root", group => "root", mode => "0644",
	}
	file { "/etc/hosts":
		content => template("${module_name}/etc/hosts.erb"),
		owner => "root", group => "root", mode => "0644",
	}



	package { "krb5-user": ensure => installed }
	file { "/etc/krb5.conf":
                source => "puppet:///modules/${module_name}/etc/krb5.conf",
                owner => "root", group => "root", mode => "0644",
	}



	file { "/etc/logrotate.d/rsyslog":
		source => "puppet:///modules/${module_name}/etc/logrotate.d/rsyslog",
		owner => "root", group => "root", mode => "0644",
		require => Package["rsyslog"],
	}



	package { "tzdata": ensure => installed }
	file { "/etc/localtime":
		source => "/usr/share/zoneinfo/Europe/Prague",
		links => "follow",
		require => Package["tzdata"]
	}
	file { "/etc/timezone":
	        content => "Europe/Prague\n",
	}
	file_line{ "locale en_US.UTF-8 UTF-8": path => "/etc/locale.gen", line => "en_US.UTF-8 UTF-8",
		require => Package["locales"], notify => Exec["locale-gen"],
	}
	exec { "locale-gen":
		command => "/usr/sbin/locale-gen",
		refreshonly => true,
	}

	
	# Nastaveni voleb v sshd_config
	service{ "ssh": }
	augeas { "etc_sshd_config":
		context => '/files/etc/ssh/sshd_config',
	        changes => [
	        	"set /files/etc/ssh/sshd_config/GSSAPIAuthentication yes",
	                "set /files/etc/ssh/sshd_config/GSSAPICleanupCredentials yes",
	                "set /files/etc/ssh/sshd_config/PermitRootLogin prohibit-password",
			],
		require => Package["openssh-server"],
		notify => Service["ssh"],
	}


	# disable UUID in grub configs, causes more trouble than it solves
	if ( file_exists("/etc/default/grub") == 1 ) {
		augeas { "/etc/default/grub" :
			context => "/files/etc/default/grub",
			changes => [
				"set GRUB_DISABLE_LINUX_UUID true",
				"set GRUB_DISABLE_OS_PROBER true",
				"set GRUB_CMDLINE_LINUX_DEFAULT '\"net.ifnames=0\"'",
			],
			notify => Exec["update-grub"],
		}
		exec { "update-grub":
			command => "/usr/sbin/update-grub",
			refreshonly => true,
		}
	}



	file { "/usr/local/bin/pa.sh":
		ensure => link, target => "/puppet/metalib/bin/pa.sh",
	}
	service { "puppet":
		ensure => stopped,
		enable => false,
	}

	file_line { "global vimrc syntax on":
		path => "/etc/vim/vimrc", line => "syntax on",
	}
	file { "/root/.vimrc":
		ensure => file,
		owner => "root", group => "root", mode => "0644",
	}
}
