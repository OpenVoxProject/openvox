# Changelog

All notable changes to this project will be documented in this file.

## [8.22.1](https://github.com/openvoxproject/openvox-agent/tree/8.22.1) (2025-08-26)

[Full Changelog](https://github.com/openvoxproject/openvox-agent/compare/8.22.0...8.22.1)

**Fixed bugs:**

- Revert puppet -\> openvox rename [\#116](https://github.com/OpenVoxProject/openvox-agent/pull/116) ([nmburgan](https://github.com/nmburgan))

## [8.22.0](https://github.com/openvoxproject/openvox-agent/tree/8.22.0) (2025-08-25)

[Full Changelog](https://github.com/openvoxproject/openvox-agent/compare/8.21.1...8.22.0)

**Merged pull requests:**

- Promotions for 8.22.0 and fix for renaming the puppet component [\#110](https://github.com/OpenVoxProject/openvox-agent/pull/110) ([nmburgan](https://github.com/nmburgan))
- Change puppet component to openvox [\#109](https://github.com/OpenVoxProject/openvox-agent/pull/109) ([nmburgan](https://github.com/nmburgan))
- Remove EOL platforms [\#108](https://github.com/OpenVoxProject/openvox-agent/pull/108) ([nmburgan](https://github.com/nmburgan))
- Add Ubuntu 25.04 [\#107](https://github.com/OpenVoxProject/openvox-agent/pull/107) ([genebean](https://github.com/genebean))
- Updates for FIPS agents [\#106](https://github.com/OpenVoxProject/openvox-agent/pull/106) ([nmburgan](https://github.com/nmburgan))
- OSX non-root user changes [\#105](https://github.com/OpenVoxProject/openvox-agent/pull/105) ([shaun-rutherford](https://github.com/shaun-rutherford))
- Remove pxp-agent, add execution\_wrapper [\#101](https://github.com/OpenVoxProject/openvox-agent/pull/101) ([nmburgan](https://github.com/nmburgan))

## [8.21.1](https://github.com/openvoxproject/openvox-agent/tree/8.21.1) (2025-07-23)

[Full Changelog](https://github.com/openvoxproject/openvox-agent/compare/8.21.0...8.21.1)

**Fixed bugs:**

- Stop passing --\[no-\]check-prereqs to install.rb [\#96](https://github.com/OpenVoxProject/openvox-agent/pull/96) ([ekohl](https://github.com/ekohl))

**Merged pull requests:**

- Promote puppet to 8.21.0-\>8.21.1 [\#98](https://github.com/OpenVoxProject/openvox-agent/pull/98) ([bastelfreak](https://github.com/bastelfreak))
- \(maint\) Drop debian-10 from testing matrix [\#93](https://github.com/OpenVoxProject/openvox-agent/pull/93) ([jpartlow](https://github.com/jpartlow))

## [8.21.0](https://github.com/openvoxproject/openvox-agent/tree/8.21.0) (2025-07-09)

[Full Changelog](https://github.com/openvoxproject/openvox-agent/compare/8.20.0...8.21.0)

**Implemented enhancements:**

- openvox: Update 8.20.0-\>8.21.0 [\#87](https://github.com/OpenVoxProject/openvox-agent/pull/87) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- OpenVox: Remove build dependency to facter [\#86](https://github.com/OpenVoxProject/openvox-agent/pull/86) ([bastelfreak](https://github.com/bastelfreak))

## [8.20.0](https://github.com/openvoxproject/openvox-agent/tree/8.20.0) (2025-07-09)

[Full Changelog](https://github.com/openvoxproject/openvox-agent/compare/8.19.2...8.20.0)

**Implemented enhancements:**

- puppet-runtime: Update 202505151-\>202507081 [\#78](https://github.com/OpenVoxProject/openvox-agent/pull/78) ([bastelfreak](https://github.com/bastelfreak))
- Switch from Facter to OpenFact & openvox: Update 8.19.2-\>.20.0 [\#77](https://github.com/OpenVoxProject/openvox-agent/pull/77) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- \[Bug\]: MacOS package build not reproducible [\#75](https://github.com/OpenVoxProject/openvox-agent/issues/75)
- Rename puppet leftovers to openvox [\#84](https://github.com/OpenVoxProject/openvox-agent/pull/84) ([bastelfreak](https://github.com/bastelfreak))
- Rename facter leftovers to openfact [\#82](https://github.com/OpenVoxProject/openvox-agent/pull/82) ([bastelfreak](https://github.com/bastelfreak))
- puppet-runtime: Fix artifacts url [\#80](https://github.com/OpenVoxProject/openvox-agent/pull/80) ([bastelfreak](https://github.com/bastelfreak))

## [8.19.2](https://github.com/openvoxproject/openvox-agent/tree/8.19.2) (2025-06-10)

[Full Changelog](https://github.com/openvoxproject/openvox-agent/compare/8.19.1...8.19.2)

**Fixed bugs:**

- \[Bug\]: warning coming out of puppet lookup in 8.19.1 [\#66](https://github.com/OpenVoxProject/openvox-agent/issues/66)
- \[Bug\]: version 8.19.0 - cannot load such file -- /opt/puppetlabs/puppet/lib/ruby/gems/3.2.0/specifications/lib/puppet/version [\#56](https://github.com/OpenVoxProject/openvox-agent/issues/56)
- openvox: Update 8.19.1-\>8.19.2 [\#73](https://github.com/OpenVoxProject/openvox-agent/pull/73) ([bastelfreak](https://github.com/bastelfreak))
- Fix openvox 7 builds [\#69](https://github.com/OpenVoxProject/openvox-agent/pull/69) ([jpartlow](https://github.com/jpartlow))

## [8.19.1](https://github.com/openvoxproject/openvox-agent/tree/8.19.1) (2025-06-03)

[Full Changelog](https://github.com/openvoxproject/openvox-agent/compare/8.19.0...8.19.1)

**Fixed bugs:**

- Update puppet component to 8.19.1 [\#57](https://github.com/OpenVoxProject/openvox-agent/pull/57) ([smortex](https://github.com/smortex))

## [8.19.0](https://github.com/openvoxproject/openvox-agent/tree/8.19.0) (2025-05-31)

[Full Changelog](https://github.com/openvoxproject/openvox-agent/compare/8.18.1...8.19.0)

**Implemented enhancements:**

- Update puppet component to 8.19.0 [\#49](https://github.com/OpenVoxProject/openvox-agent/pull/49) ([smortex](https://github.com/smortex))

## 8.18.1

* Fix for the PR removing the ContentsDescription class.

## 8.18.0 (not released)

* Further fix for the file descriptor bug from last release.
* Removed unused ContentsDescription class that has been unused for a long time in favor of metadata.json.
* Added support for Fedora 43 x86_64 and aarch64. Note that Fedora 43 has not yet been released and this agent is being built with the state of the OS at build time, so treat this agent accordingly.
* The openvox-agent package now "provides" puppet-agent, so any projects that require a puppet-agent package can now use openvox-agent more seamlessly. It also now bounds the version for "replaces" on puppet-agent so that package managers don't complain.

## 8.17.0

* Fixed an issue where we attempted to close the file descriptor of the directory we are iterating. [openvox/puppet#9552](https://github.com/puppetlabs/puppet/pull/9552)
* Added Debian 13 aarch64 and x86_64. This is built using a pre-release Trixie container image. Consider this agent pre-release until Debian 13 is officially released and we build using the official image. However, you should have no problems using this agent with Trixie.
* Added amazon-2-x86_64. You may continue to use the el-7-x86_64 agent for this platform, but this one is built specifically with an amazonlinux:2 container image.

## 8.16.0

* Updated curl to 8.13.0
* Updated dmidecode to 3.6
* Updated libffi to 3.4.8
* Update libxml2 to 2.13.8 to address CVE-2024-56171, CVE-2025-24928, CVE-2025-32414, CVE-2025-32415
* Updated libxslt to 1.1.43 to address CVE-2024-55549, CVE-2025-24855
* Updated OpenSSL to 3.0.16 to address CVE-2024-13176, CVE-2024-9143
* Updated Ruby to 3.2.8 to address CVE-2025-27219, CVE-2025-27220, CVE-2025-27221
* Updated eruby to 1.13.1
* Updated ffi to 1.17.2
* Updated hiera-eyaml to 4.2.0
* Updated mini_portile2 to 2.8.8
* Updated nokogiri to 1.18.7 to address several CVEs that were present in the vendored versions of libxml2 and libxslt. This is component is only present in the MacOS client. CVE-2023-29469, CVE-2023-28484, CVE-2024-25062, CVE-2024-25062, CVE-2024-34459, CVE-2024-40896, CVE-2025-24928, CVE-2025-24855
* Updated optimist to 3.2.1
* Updated prime to 0.1.3
* Updated sys-filesystem to 1.4.5
* Updated boost to 1.82.0
* Removed yaml-cpp, as this was only used for the C++ version of Facter which is no longer used.
* For the Windows agent, the path includes the space in "C:\Program Files\Puppet Labs" once again to maintain compatibility with certain modules.

## 8.15.0

* Added support for Fedora 42 x86_64 and aarch64.

## 8.14.0

* Added Windows x64 support. This should work on Windows Server 2016+ and Windows 10+.
* Updated Boost to 1.82.0 for Windows only in order to fix a bug needed for buidling the Windows agent. https://github.com/boostorg/locale/commit/41868c62a0519799696b544518f1efd831ff71c2
* Fixed issue on Fedora 41 with dnf5. We were using deprecated yum flags -d and -e. Since we don't support anything older than EL7, in which these were already deprecated, they have been removed.

## 8.13.0

* Added MacOS 15 (Sequoia) ARM64 support. No changes to other OS packages. Downloads for MacOS builds can be found at https://artifacts.overlookinfratech.com/#macos/

## 8.12.1

* Fix version in puppet component

## 8.12.0

* Make builds reproducible
* Add conflicts/replaces metadata on puppet-agent
* Update branding text to OpenVox in various commands
* Update rexml to 3.4.1 to address CVE-2024-49761
* Update curl to 8.12.1 to address CVE-2025-0167, CVE-2025-0665, and CVE-2025-0725, even though it should not affect OpenVox
* Update semantic_puppet to 1.1.1 to fix a typo in a method name
* Update Ruby to 3.2.7
* Add support for Fedora 41 (x86_64 and aarch64)

## 8.11.0

* Initial openvox-agent release. Based on Puppet 8.10.0, with additional support for fedora-40-aarch64, el-10-x86_64, and el-10-aarch64.


\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
