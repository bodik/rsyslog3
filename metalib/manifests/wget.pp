# Class for installling wget, and defines download resource.
class metalib::wget() {
	package { "wget": ensure => installed, }

	# downloads external resource to local file and sets proper persmissions
	# @example Usage
	#   metalib::wget::download { "/etc/krb5.conf":
        #     uri => "https://download.zcu.cz/public/config/krb5/krb5.conf",
        #     owner => "root", group => "root", mode => "0644",
        #     timeout => 900;
	#   } 
	# @param uri uri to dowload
	# @param timeout timeout for operation
	# @param owner destination file owner
	# @param group destination file group
	# @param mode destrination file mode
	define download ($uri, $timeout = 300, $owner = "root", $group = "root", $mode = "0644") {
		exec { "download $uri":
			command => "/usr/bin/wget -q '$uri' -O $name",
			creates => $name,
			timeout => $timeout,
			require => Package[ "wget" ],
	        }
		file { "$name":
			owner => $owner, group => $group, mode => $mode,
			require => Exec["download $uri"],
		}
	}
}
