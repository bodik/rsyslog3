= rsyslog

Module provides way to develop and install rsyslog, and configures the instance
to server or client mode. By default clients forwards all messages to server,
server stores all logs on disk and forwards them to rediser (or other tcp line
oriented server) for further analysis. Classes supports autodiscovery of
components by avahi or statically by parameter.


## defined_types: rsyslog::install::config


## puppet_classes: rsyslog::client

Class will ensure installation of rsyslog packages and configures daemon to client mode eg. :
- forwards all logs to rsyslog server using omrelp or omgssapi on krb5 enabled nodes

### Parameters

**rsyslog_server** -- hostname or ip to forward all logs to (default undef)

**rsyslog_server_auto** -- perform rsyslog server autodiscovery by avahi (defult true)

**rsyslog_server_service** -- name of rsyslog server service to discover (default "_syselgss._tcp")

### Examples

install default version, perform autodiscovery and forward logs to rsyslog server

```
include rsyslog::client
```
install, forwardm logs to designated server node

```
class { "rsyslog::client":
  rsyslog_server => "1.2.3.4",
}
```
install rsyslog client and do not forward gathered log anywhere

```
class { "rsyslog::server":
  rsyslog_auto => false,
}
```

## puppet_classes: rsyslog::dev

Class will ensure installcompilation and debugging rsyslog8. Also disables
stripping binaries for whole node because of generation debug enabled
packages.

### Examples

Usage

```
include rsyslog::dev
```

## puppet_classes: rsyslog::install

Class will ensure installation of rsyslog packages from rsyslog metacentrum dev repository


## puppet_classes: rsyslog::server

Class will ensure installation of rsyslog packages and configures daemon to server mode eg. :
- imtcp, imrelp, optionally imgssapi on krb5 enabled nodes
- stores all incoming logs into IP based directory stucture
- optionaly forwards all gathered logs to rediser for analytics (omfwd).
- announce self to others using avahi.

### Parameters

**rediser_server** -- hostname or ip to forward all logs to for analytics, has precedence over rediser_auto

**perhost** -- 

**pertime** -- 

**rediser_auto** -- 

**rediser_service** -- 

**avahi_broadcast** -- 

### Examples

install, perform autodiscovery and forward logs to rediser

```
include rsyslog::server
```
install, forwardm logs to designated analytics node

```
class { "rsyslog::server": rediser_server => "1.2.3.4", }
```
install and do not forward gathered log anywhere

```
class { "rsyslog::server": rediser_auto => false, }
```

