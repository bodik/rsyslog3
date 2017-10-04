Puppet::Functions.create_function(:generate_password) do
	# generates password
	#
	# @return generated password
	# @param outlen optional, length of the password to generate
        def generate_password(*outlen)

                out = Facter::Util::Resolution.exec("/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print $1}'")
                if out.nil?
                        return :undef
                else
			if outlen.empty?
	                        return out
			else
				return out[0, outlen[0]]
			end
                end
        end
end
