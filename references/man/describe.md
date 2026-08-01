---
layout: default
built_from_commit: 3d665fe7a4a7dfa794748a310db79025a4d932cc
title: 'Man Page: puppet describe'
canonical: "/openvox/latest/man/describe.html"
---

# Man Page: puppet describe

> **NOTE:** This page was generated from the OpenVox source code on 2026-08-01 22:12:56 +0000

## NAME
**puppet-describe** - Display help about resource types available to
OpenVox

## SYNOPSIS
Prints help about resource types, providers, and metaparameters
installed on an OpenVox node.

## USAGE
puppet describe \[-h\|\--help\] \[-s\|\--short\] \[-p\|\--providers\]
\[-l\|\--list\] \[-m\|\--meta\]

## OPTIONS
\--help

:   Print this help text

\--providers

:   Describe providers in detail for each type

\--list

:   List all types

\--meta

:   List all metaparameters

\--short

:   List only parameters without detail

## EXAMPLE
    $ puppet describe --list
    $ puppet describe file --providers
    $ puppet describe user -s -m

## AUTHOR
David Lutterkort

## COPYRIGHT
Copyright (c) 2011 Puppet Inc.; Copyright (c) 2024 Vox Pupuli. Licensed
under the Apache 2.0 License
