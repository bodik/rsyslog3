## kerberos rekeying howto

* must be run on kdc master node (kadmin local)
* operator must have valid credentials to access managed (--keytab ssh://...) and configuration management (--puppetstorage ssh://...) node


### rekeying procedure

1. install rekey utility
	* git clone rsyslog3.git repo
	* create `/etc/heimdal-kdc/kadmin-rekey.conf` = `/etc/heimdal-kdc/kdc.conf` + `/etc/krb5.conf` + edit `[kadmin] default_keys`
	* test rekeying local test keytab (see `tests/rekey_service_heimdal.sh`)


2. rekey principals
	* list principals `krb/bin/kadmin-list-heimdal.sh REALM | grep des-`
	* rekey principal `krb/bin/rekey-heimdal.py --keytab X --principal Y --puppetstorage Z`, eg.
```
export FQDN="xxx"; krb/bin/rekey-heimdal.py --keytab ssh://root@${FQDN}/etc/krb5.keytab --principal host/${FQDN}@REALM --puppetstorage ssh://root@puppetmaster/path/krb5.keytab.${FQDN}
```


3. wait for max renew time for existing service tickets to expire


4. cleanup keytab `krb/bin/keytab-cleanup-heimdal.py --keytab X --principal Y --puppetstorage Z`
```
export FQDN="xxx"; krb/bin/keytab-cleanup-heimdal.py --keytab ssh://root@${FQDN}/etc/krb5.keytab --principal host/${FQDN}@REALM --puppetstorage ssh://root@puppetmaster/path/krb5.keytab.${FQDN}
```


5. cleanup keytab backups (`*.rekeybackup.*`)
