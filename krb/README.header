# krb -- kerberos basic module

handles installation of the KDC server (Heimal and MIT), basic keytab
bootstrapping for cloud testing, client autodiscovery and configuration 


## creating simple crossrealm

```
pa.sh -e 'class {"krb::kdcheimdal": realm=>"heimdal"}'
pa.sh -e 'class {"krb::user": realm=>"heimdal", kdc_server=>$fqdn}'

ank --use-defaults --random-key krbtgt/mit@heimdal
cpw --keepold -p '' krbtgt/mit@heimdal
```

```
pa.sh -e 'class {"krb::kdcmit": realm=>"mit"}'
pa.sh -e 'class {"krb::user": realm=>"mit", kdc_server=>$fqdn}'

ank -randkey krbtgt/mit@heimdal
cpw -e des3-cbc-sha1,aes256-cts-hmac-sha1-96 -keepold -pw '' krbtgt/mit@heimdal
```

* fix krb5.conf [[domain_realm] mapping
