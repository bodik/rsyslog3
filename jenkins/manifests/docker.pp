# installs docker
#
# @example Usage
#   class { "jenkins::docker": }
#
class jenkins::docker() {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	ensure_resource("class", "apt", {})
	apt::source { 'docker':
		location   => 'http://apt.dockerproject.org/repo',
		release => 'debian-stretch',
		repos => 'main',
		include => { 'src' => false },
        	key         => '58118E89F3A912897C070ADBF76221572C52609D',
	}
	package { "aufs-dkms": ensure => installed }
	package { "docker-engine": 
		ensure => installed, 
		require => [Apt::Source["docker"], Package["aufs-dkms"]],
	}

	file { "/usr/local/bin/docker.init":
		ensure => link, target => "/puppet/jenkins/bin/docker.init",
	}
}

