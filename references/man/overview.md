---
layout: default
built_from_commit: f7b1a950d990274b9f352eb7aa0cd93ee6067df1
title: OpenVox Man Pages
canonical: "/puppet/latest/man/overview.html"
---

# OpenVox Man Pages

> **NOTE:** This page was generated from the OpenVox source code on 2026-07-14 18:42:24 +0000



OpenVox's command line tools consist of a single `puppet` binary with many subcommands. The following subcommands are available in this version of OpenVox:

Core Tools
-----

These subcommands form the core of OpenVox's tool set, and every user should understand what they do.

- [puppet agent](agent.md)
- [puppet apply](apply.md)
- [puppet lookup](lookup.md)
- [puppet module](module.md)
- [puppet resource](resource.md)


> Note: The `puppet cert` command is available only in Puppet versions prior to 6.0. For 6.0 and later, use the [`puppetserver cert`command](https://docs.openvoxproject.org/openvox/latest/puppet_server_ca_cli.html).

Secondary subcommands
-----

Many or most users need to use these subcommands at some point, but they aren't needed for daily use the way the core tools are.

- [puppet config](config.md)
- [puppet describe](describe.md)
- [puppet device](device.md)
- [puppet doc](doc.md)
- [puppet epp](epp.md)
- [puppet generate](generate.md)
- [puppet help](help.md)
- [puppet node](node.md)
- [puppet parser](parser.md)
- [puppet plugin](plugin.md)
- [puppet script](script.md)
- [puppet ssl](ssl.md)


Niche subcommands
-----

Most users can ignore these subcommands. They're only useful for certain niche workflows, and most of them are interfaces to OpenVox's internal subsystems.

- [puppet catalog](catalog.md)
- [puppet facts](facts.md)
- [puppet filebucket](filebucket.md)
- [puppet report](report.md)


