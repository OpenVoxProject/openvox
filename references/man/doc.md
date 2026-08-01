---
layout: default
built_from_commit: 3d665fe7a4a7dfa794748a310db79025a4d932cc
title: 'Man Page: puppet doc'
canonical: "/openvox/latest/man/doc.html"
---

# Man Page: puppet doc

> **NOTE:** This page was generated from the OpenVox source code on 2026-08-01 22:12:56 +0000

## NAME
**puppet-doc** - Generate Puppet references for OpenVox

## SYNOPSIS
Generates a reference for all resource types. Largely meant for internal
use. (Deprecated)

## USAGE
puppet doc \[-h\|\--help\] \[-l\|\--list\] \[-r\|\--reference
*reference-name*\]

## DESCRIPTION
This deprecated command generates a Markdown document to stdout
describing all installed resource types or all allowable arguments to
puppet executables. It is largely meant for internal use and is used to
generate the reference documents which can be posted to a website.

For Puppet module documentation (and all other use cases) this command
has been superseded by the \"puppet-strings\" module - see
https://github.com/puppetlabs/puppetlabs-strings for more information.

This command (puppet-doc) will be removed in a future release.

## OPTIONS
\--help

:   Print this help message

\--reference

:   Build a particular reference. Get a list of references by running
    \'puppet doc \--list\'.

## EXAMPLE
    $ puppet doc -r type > /tmp/type_reference.markdown

## AUTHOR
Luke Kanies

## COPYRIGHT
Copyright (c) 2011 Puppet Inc.; Copyright (c) 2024 Vox Pupuli. Licensed
under the Apache 2.0 License
