#TODO: documentation
class krb::nfsclient(
        $nfs_server = undef,
) {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")


        if ( $nfs_server ) {
                $nfs_server_real = $nfs_server
        } else {
                $nfs_server_real = avahi_findservice("_kdc._udp")
        }

        package { "nfs-common": ensure => installed }

        augeas { "/etc/default/nfs-common":
                context => "/files/etc/default/nfs-common",
                changes => ["set NEED_IDMAPD yes", "set NEED_GSSD yes"],
                require => Package["nfs-common"],
                notify => Service["auth-rpcgss-module", "rpc-gssd", "rpc-svcgssd"],
        }

        service { ["auth-rpcgss-module", "rpc-gssd", "rpc-svcgssd"]:
                ensure => "running",
                require => Package["nfs-common"],
        }

        file { "/nfsroot":
                ensure => directory,
                owner => "root", group => "root", mode => "0644",
        }

        mount { "/nfsroot":
                ensure => mounted,
                device => "${nfs_server_real}:/nfsroot",
                fstype => "nfs4",
                options => "sec=krb5",
                require => Service["auth-rpcgss-module", "rpc-gssd", "rpc-svcgssd"],
        }
}
