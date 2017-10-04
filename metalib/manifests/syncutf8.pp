# Manages copy of directory structure from src to dst. Used when file resource
# does not work (ca directories with utf-8 filenames)
#
# @example Usage
#   metalib::syncutf8 { "syncutf8 /home/apache/usr/lib/ssl":
#     src_dir => "/usr/lib/ssl",
#     dest_dir => "/home/apache/usr/lib/ssl",
#     require => File["/home/apache/usr/lib"],
#   }
#
# @param src_dir source directory
# @param dest_dir destination directory
define metalib::syncutf8(
	$src_dir,
	$dest_dir,
) {
	exec { "syncutf8 $src_dir $dest_dir":
		command => "/usr/bin/rsync --delete --recursive --links $src_dir/ $dest_dir 1>/dev/null",
		unless => "/usr/bin/diff -rua $src_dir $dest_dir 1>/dev/null"
	}
}

