Puppet::Functions.create_function(:avahi_findservice) do
	# simple wrapper for avahi-browse
	#
	# @return string or hostname representing discovered service
	# @param name name of the service to discover
	def avahi_findservice(name)
		out= Facter::Util::Resolution.exec('/puppet/metalib/bin/avahi_findservice.sh '+name)
		if out.nil?
			return :undef
		else
			return out
		end
	end
end
