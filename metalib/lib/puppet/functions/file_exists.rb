Puppet::Functions.create_function(:file_exists) do
	# checks for existence of file by path
	# http://www.xenuser.org/downloads/puppet/xenuser_org-010-check_if_file_exists.pp
	#
	# @return 1 when file exist, otherwise returns 0
	# @param path path to check
	def file_exists(path)
		if File.exists?(path)
			return 1
		else
			return 0
		end
	end
end
