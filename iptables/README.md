## puppet_classes: iptables

Class will ensure installation of old-school iptables and ip6tables scripts
with systemd support. Installs selected rulesets or sets default based on
manifest logic, fqdns or default. Supports PRIVATE_ files which are not part
of the module, for more information reat the manifest itself.

### Parameters

**rules_v4** -- file with ipv4 ruleset

**rules_v6** -- file with ipv6 ruleset

### Examples

Usage

```
class { "iptables":
   rules_v4 => "puppet:///modules/${module_name}/somefile",
}
```

