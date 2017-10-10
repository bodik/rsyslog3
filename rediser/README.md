# rediser

rediser daemon spooling messages from various tcp sources to redis queue 


## defined_types: rediser::config

defined resources


## puppet_classes: rediser

Class will install redis server and rediser -- tcp daemon which reads line
separated messages from clients and pushes them into redis queue. Rediser
will announce itself to others using avahi.

### Parameters

**install_dir** -- installation directory

**service_user** -- user running the service

**avahi_broadcast** -- mdns service broadcasting

### Examples

Usage class { "rediser": }

```

```

