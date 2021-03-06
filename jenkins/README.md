# jenkins -- Module for jenkins automation

Module provides installation and basic configuration and set of script for
Jenkins to perform semiautomatic creation of cloud nodes with designated roles
installed. It is used mainly for development of puppet modules with automatic
testing and playing testing scenarios for rsylog component. Primarily it should
be installed to private VM since Jenkins must be provisioned with user
credentials and module does not configure any security for Jenkins.


## Cloud/Virtualization helpers

Cloud/Virtualization helpers provides unified means for creating VM instalnces
and shell acces to them.  All helpers take $VMNAME (environment variable) as
instance selector or set a default one. All helpers provides subset of
primitives:

* list     -- lists running VMs
* build    -- build the instance (prepares local image; kvm, xen)
* start    -- boot the instance
* status   -- get status of instance
* shutdown -- gracefully shuts down the instance
* destroy  -- destroys the instance immediately
* ssh      -- gets shell access to the instance

* creds    -- initializes users credentials for accessing the cloud
* login    -- initializes credential caches (metacloud only)
* front    -- gets shell access to cloud/virtualization frontend


### metacloud.init

Used for hosting VMs in OpenNebula cloud using onetools. Uses static templates
(templates.*) for VM provisioning. Helper must initialize users credentials to
/dev/shm (`/dev/shm/username` and `/dev/shm/usercert.pem`)

```
# run initializer
metacloud.init creds
# transfer or create local credentials
jenkins@debian:/tmp$ scp user@remote:secretsdir/* /dev/shm
# create auth cookie  
jenkins@debian:/tmp$ metacloud.init login
# ensure templates in OpenNebula/Metacloud
jenkins@debian:/tmp$ metacloud.init templates
# quit jenkins user shell
jenkins@debian:/tmp$ exit

# work with jenkins
browser http://localhost:8081
# work with instances
VMNAME=RDEVCLIENTX metacloud.init build
VMNAME=RDEVCLIENTX metacloud.init start
VMNAME=RDEVCLIENTX metacloud.init status
VMNAME=RDEVCLIENTX metacloud.init list
VMNAME=RDEVCLIENTX metacloud.init ssh '/bin/true'
VMNAME=RDEVCLIENTX metacloud.init ssh 'cd /puppet && sh elk.install.sh'
```
 
### vbox.init/vboxlocal.init

Used for HaaS hosting VMs in Oracle's Virtualbox running under unprivileged
user. Uses templates within virtualbox itself for VM provisioning. Helper must
have access to frontend hostname (`~/.ssh/haas.server`), frontend username
(`~/.ssh/haas.username`) and ssh-key credentials (`~/.ssh/haas`).

```
VMNAME=ABC vbox.init build
VMNAME=ABC vbox.init start
VMNAME=ABC vbox.init list
VMNAME=ABC vbox.init status
VMNAME=ABC vbox.init ssh '/bin/true'
```

### Scripts

**bin/haas_vm_cleanup.sh** -- haas build helper, executes all modules cleanups

**bin/haas_vm_finalize.sh** -- haas helper, invokens racerts and configuration scripts for all modules

**bin/haas_vm_finalize_lib.sh** -- haas build helper, shell functions library

**bin/haas_vm_generate_w3cname.sh** -- haas jenkins finalizer helper

**bin/haas_vm_prepare.sh** -- haas helper, manages node basic configuration for clean VM import

**bin/metacloud.init** -- jenkins virtualization frontend

**bin/popjobs.sh** -- dev script, pops current jenkins jobs setting to git repo

**bin/run_jobs.sh** -- jekins helper, run set of jekins jobs based od name regexp

**bin/vbox.init** -- jenkins virtualization frontend

**bin/vboxlocal.init** -- jenkins virtualization fontend helper

## puppet_classes: jenkins

Class provides Jenkins installation from vendor repository packages and
configures basic set of jobs for building host with specified roles as well
as running autotests at the ends of the scenarios.

### Examples

Usage

```
class { jenkins: }
```

