---
layout: default
built_from_commit: f7b1a950d990274b9f352eb7aa0cd93ee6067df1
title: Report Reference
toc: columns
canonical: "/openvox/latest/report.html"
---

# Report Reference

> **NOTE:** This page was generated from the OpenVox source code on 2026-07-14 18:42:24 +0000




OpenVox can generate a report after applying a catalog. This report includes
events, log messages, resource statuses, and metrics and metadata about the run.
OpenVox agent sends its report to an OpenVox server, and puppet apply
processes its own reports.

OpenVox Server and puppet apply will handle every report with a set of report
processors, configurable with the `reports` setting in puppet.conf. This page
documents the built-in report processors.

See [About Reporting](https://docs.openvoxproject.org/openvox/latest/reporting_about.html)
for more details.

http
----
Send reports via HTTP or HTTPS. This report processor submits reports as
POST requests to the address in the `reporturl` setting. When a HTTPS URL
is used, the remote server must present a certificate issued by the OpenVox
CA or the connection will fail validation. The body of each POST request
is the YAML dump of a Puppet::Transaction::Report object, and the
Content-Type is set as `application/x-yaml`.

log
---
Send all received logs to the local log destinations.  Usually
the log destination is syslog.

store
-----
Store the yaml report on disk.  Each host sends its report as a YAML dump
and this just stores the file on disk, in the `reportdir` directory.

These files collect quickly -- one every half hour -- so it is a good idea
to perform some maintenance on them if you use this report (it's the only
default report).

