Puppet::Functions.create_function(:myexec) do
	# simple wrapper for custom execs
	# 
	# @return returns command output
	# @param cmd line to execute using shell
        def myexec(cmd)
                out = Facter::Util::Resolution.exec(cmd)
                if out.nil?
                        return :undef
                else
                        return out
                end
        end
end
