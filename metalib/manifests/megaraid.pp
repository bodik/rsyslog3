# Class for installing megaraid and sas2ircu utils for Dell PERC raid controllers.
#
# @example Usage
#  class { "metalib::megaraid": type => "megacli" }
#
class metalib::megaraid(
	$type,
) {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	# elk repos
	if !defined(Class['apt']) {
        	class { 'apt': }
	}
	apt::source { "megaraid":
		location   => "http://hwraid.le-vert.net/debian",
		release => "jessie", repos => "main",
		include => { "src" => false },
		key => "0073C11919A641464163F7116005210E23B3D3B4",
	}

	case $type {
		'megacli': { $packages = ["megacli", "megaclisas-status"] }
		'sas2ircu': { $packages = ["sas2ircu", "sas2ircu-status"] }
	}

	package { $packages:
		ensure => installed,
		require => [Apt::Source["megaraid"], Exec["apt_update"]],
	}
 	package { "sysbench": ensure => installed, }

}
