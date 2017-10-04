## defined_types: lamp::apache2::a2disconf

Internal. Disables apache2 config


## defined_types: lamp::apache2::a2dismod

Internal. Disables apache2 module


## defined_types: lamp::apache2::a2enconf

Internal. Enables apache2 config


## defined_types: lamp::apache2::a2enmod

Internal. Enables apache2 module


## puppet_classes: lamp::apache2

Manages basic installation and config of apache2 webserver, configures
status, dir, default virtualhost, prefork config, ...

### Examples

Usage

```
include lamp::apache2
```

## puppet_classes: lamp::php

Internal. Installs php module for apache2 webserver, installs basic test scripts and dashboard


