# metalib -- generic masterless puppet module

Contains various classes, resources and functions used by other modules

## Scripts

**bin/avahi_findservice.sh** -- discover service on the local network, returns URI or hostname associated with the service

**bin/generate_module_doc.py** -- puppet-strings documentation generator script

**bin/install_sslselfcert.sh** -- generates x509 self-signed certificate to specified directory. used by various manifests

**bin/lib.sh** -- shell functions library

**bin/pa.sh** -- masterless puppet frontend

**bin/sysbench-disk.sh** -- cloud performance testing script

## defined_types: metalib::syncutf8

Manages copy of directory structure from src to dst. Used when file resource
does not work (ca directories with utf-8 filenames)

### Parameters

**src_dir** -- source directory

**dest_dir** -- destination directory

### Examples

Usage

```
metalib::syncutf8 { "syncutf8 /home/apache/usr/lib/ssl":
  src_dir => "/usr/lib/ssl",
  dest_dir => "/home/apache/usr/lib/ssl",
  require => File["/home/apache/usr/lib"],
}
```

## defined_types: metalib::wget::download

downloads external resource to local file and sets proper persmissions

### Parameters

**uri** -- uri to dowload

**timeout** -- timeout for operation

**owner** -- destination file owner

**group** -- destination file group

**mode** -- destrination file mode

### Examples

Usage

```
metalib::wget::download { "/etc/krb5.conf":
  uri => "https://download.zcu.cz/public/config/krb5/krb5.conf",
  owner => "root", group => "root", mode => "0644",
  timeout => 900;
}
```

## puppet_classes: metalib::avahi

Class for installling avahi utils and resolving daemon. This class is used
during dynamic cloud autodiscovery by other classes.

### Examples

Usage

```
include metalib::avahi
```

## puppet_classes: metalib::base

Class manages basic set of setting and packages which should/should not be
present on every/new node.

### Examples

Usage

```
include metalib::base
```

## puppet_classes: metalib::fail2ban

Internal. Installs fail2ban with basic config (sshd)


## puppet_classes: metalib::megaraid

Class for installing megaraid and sas2ircu utils for Dell PERC raid controllers.

### Parameters

**type** -- 

### Examples

Usage

```
class { "metalib::megaraid": type => "megacli" }
```

## puppet_classes: metalib::postfix

Internal. Installs postfix as local MTA


## puppet_classes: metalib::puppet_cleanup

Internal. Cleans up /var/lib/puppet from old files and reports


## puppet_classes: metalib::sysctl_hardnet

Internal. Hardens networking on linux box.


## puppet_classes: metalib::virtualbox

Class for installing Oracle's Virtualbox for Debian Stretch.

### Examples

Usage

```
include metalib::virtualbox
```

## puppet_classes: metalib::wget

Class for installling wget, and defines download resource.


## puppet_functions: avahi_findservice

### Parameters

**name** -- name of the service to discover

### Return

string or hostname representing discovered service


## puppet_functions: file_exists

### Parameters

**path** -- path to check

### Return

1 when file exist, otherwise returns 0


## puppet_functions: generate_password

### Parameters

***outlen** -- optional, length of the password to generate

### Return

generated password


## puppet_functions: myexec

### Parameters

**cmd** -- line to execute using shell

### Return

returns command output


