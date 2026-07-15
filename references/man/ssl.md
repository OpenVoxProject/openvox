---
layout: default
built_from_commit: f7b1a950d990274b9f352eb7aa0cd93ee6067df1
title: 'Man Page: puppet ssl'
canonical: "/openvox/latest/man/ssl.html"
---

# Man Page: puppet ssl

> **NOTE:** This page was generated from the OpenVox source code on 2026-07-14 18:42:24 +0000

## NAME
**puppet-ssl** - Manage SSL keys and certificates for OpenVox SSL
clients

## SYNOPSIS
Manage SSL keys and certificates for clients needing to communicate with
an OpenVox infrastructure.

## USAGE
puppet ssl *action* \[-h\|\--help\] \[-v\|\--verbose\] \[-d\|\--debug\]
\[\--localca\] \[\--target CERTNAME\]

## OPTIONS
- \--help: Print this help message.

- \--verbose: Print extra information.

- \--debug: Enable full debugging.

- \--localca Also clean the local CA certificate and CRL.

- \--target CERTNAME Clean the specified device certificate instead of
  this host\'s certificate.

- \--if-expiring-in DURATION When renewing a certificate only renew if
  the certificate is valid for less than this amount of time. Duration
  can be specified as a time interval, such as 30s, 5m, 1h.

## ACTIONS
- bootstrap: Perform all of the steps necessary to request and download
  a client certificate. If autosigning is disabled, then puppet will
  wait every **waitforcert** seconds for its certificate to be signed.
  To only attempt once and never wait, specify a time of 0. Since
  **waitforcert** is an OpenVox setting, it can be specified as a time
  interval, such as 30s, 5m, 1h.

- submit_request: Generate a certificate signing request (CSR) and
  submit it to the CA. If a private and public key pair already exist,
  they will be used to generate the CSR. Otherwise, a new key pair will
  be generated. If a CSR has already been submitted with the given
  **certname**, then the operation will fail.

- generate_request: Generate a certificate signing request (CSR). If a
  private and public key pair exist, they will be used to generate the
  CSR. Otherwise a new key pair will be generated.

- download_cert: Download a certificate for this host. If the current
  private key matches the downloaded certificate, then the certificate
  will be saved and used for subsequent requests. If there is already an
  existing certificate, it will be overwritten.

- renew_cert Renew an existing and non-expired client certificate. When
  **\--if-expiring-in** option is specified, then renew the certificate
  only if it\'s going to expire in the amount of time given.

- verify: Verify the private key and certificate are present and match,
  verify the certificate is issued by a trusted CA, and check revocation
  status.

- clean: Remove the private key and certificate related files for this
  host. If **\--localca** is specified, then also remove this host\'s
  local copy of the CA certificate(s) and CRL bundle. if **\--target
  CERTNAME** is specified, then remove the files for the specified
  device on this host instead of this host.

- show: Print the full-text version of this host\'s certificate.

COPYRIGHT \-\-\-\-\-- Copyright (c) 2011 Puppet Inc. Copyright (c) 2024
Vox Pupuli Licensed under the Apache 2.0 License
