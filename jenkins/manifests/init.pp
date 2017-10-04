# Class provides Jenkins installation from vendor repository packages and
# configures basic set of jobs for building host with specified roles as well
# as running autotests at the ends of the scenarios.
#
# @example Usage
#  class { jenkins: }
#
class jenkins() {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	if !defined(Class['apt']) {
        	class { 'apt': }
	}
	apt::source { 'jenkins':
		location   => 'http://pkg.jenkins-ci.org/debian',
		release => 'binary/',
		repos => '',
		include => { "src" => false },
		key => {
			"id" => "150FDE3F7787E7D11EF4E12A9B7D32F2D50582E6",
			"source" => "http://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key"
		},
	}

	package { ["openjdk-8-jdk", "jenkins"]:
		ensure => installed,
		require => Apt::Source["jenkins"],
	}
	service { "jenkins": }

	augeas { "/etc/default/jenkins" :
		context => "/files/etc/default/jenkins",
		changes => [
			"set HTTP_PORT 8081",
			"set JAVA_ARGS '\"-Dhudson.diyChunking=false -Djava.awt.headless=true\"'",
		],
		require => Package["jenkins"],
		notify => Service["jenkins"],
	}
	file { "/var/lib/jenkins/jobs":
		ensure => directory,
		source => "puppet:///modules/${module_name}/jobs",
		recurse => true,
		owner => "jenkins", group=> "jenkins", mode=>"0644",
		require => Package["jenkins"],
		notify => Service["jenkins"],
	}
	# po uvodni instalaci konfigurak neni (2.21) a recept se nepovede
	# nekdy casem tam naskoci, ale kdyz tam je tak rozbiji chunked encoding
#	augeas { '/var/lib/jenkins/config.xml' :
#		incl => '/var/lib/jenkins/config.xml',
# 		lens    => 'Xml.lns',
#		context => '/files/var/lib/jenkins/config.xml/hudson',
#		changes => [
#			"set useSecurity/#text false",
#		],
#		require => Package["jenkins"],
#		notify => Service["jenkins"],
#	}

	#metacloud
	package { ["libexpat1-dev", "libcurl4-openssl-dev", "rake", "libxml2-dev", "libxslt1-dev", "zlib1g-dev", "gcc", "make", "ruby-dev"]:
		ensure => installed,
	}
	file { "/root/.one":
		ensure => link,
		target => "/dev/shm",
	}
	file { "/var/lib/jenkins/.one":
		ensure => link,
		target => "/dev/shm",
		require => Package["jenkins"],
	}
	exec { "gem install opennebula-cli":
		command => "/usr/bin/gem install opennebula-cli -v '~>4.4.0'",
		unless => "/usr/bin/gem list | /bin/grep opennebula-cli",
		require => [Package["ruby-dev"], Package["make"], Exec["gem install nokogiri"]],
	}
	exec { "gem install nokogiri":
		command => "/usr/bin/gem install nokogiri -v '~>1.6.6.2'",
		unless => "/usr/bin/gem list | /bin/grep nokogiri",
		require => [Package["ruby-dev"], Package["make"]],
	}
	file { "/usr/local/bin/metacloud.init":
		ensure => link,	target => "/puppet/jenkins/bin/metacloud.init",
	}

	file { "/usr/local/bin/vbox.init":
		ensure => link,	target => "/puppet/jenkins/bin/vbox.init",
	}
	file { "/usr/local/bin/vboxlocal.init":
		ensure => link,	target => "/puppet/jenkins/bin/vboxlocal.init",
	}

}

