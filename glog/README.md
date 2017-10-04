# glog -- Analytics ELK module

Module provides basic installation and management of ELK stack for various data
analytics. Includes installation of v5.x version of the stack.

## Scripts

**bin/delete-older-indexes.sh** -- cronjob script to purge old indexes acording to days parameter

**bin/elastisearch-head-install.sh** -- manifest support script

**bin/kibana-backup.sh** -- manifest support script, backups .kibana index from ESD

**bin/kibana-restore.sh** -- manifest support script, restores .kibana index to ESD, overwrites existing

**bin/listindexes.sh** -- list esd indexes using _cat interface


## defined_types: glog::glog2::esd_config

Internal. Ensures elasticsearch config line

### Parameters

**path** -- edited file path

**match** -- line to replace

**line** -- replacement

### Examples

Usage

```
glog::glog2::esd_config { "-Xms":
  path => "/etc/elasticsearch/jvm.options",
  match => "^-Xms",
  line => "-Xms${esd_heap_size}",
}
```

## defined_types: glog::glog2::kibana_config

Internal. Ensures kibana config line

### Parameters

**path** -- edited file path

**match** -- line to replace

**line** -- replacement

### Examples

Usage

```
glog::glog2::kibana_config { "server.port":
  path => "/etc/kibana/kibana.yml",
  match => "^server.port",
  line => "server.port: 5601",
}
```

## defined_types: glog::glog2::logstash_config_file

Internal. Ensures logstash single config.d file

### Examples

Usage

```
glog::glog2::logstash_config_file { "/etc/logstash/conf.d/10-input-udp.conf": }
```

## puppet_classes: glog::glog2

Class will ensure installation of ELK stack. ESD installed as data node bind
on localhost, logstash with basic set of inputs,filters and output to ESD
over http, kibana with basic settings and apache proxy configurations. haas
lamp module is expected to be present prior to glog2 installation

### Parameters

**cluster_name** -- elk cluster name

**esd_heap_size** -- esd node heap size

**esd_network_host** -- esd node bind address

### Examples

Basic usage

```
class { "glog::glog2": }
```

