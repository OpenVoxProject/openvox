# Changelog

All notable changes to this project will be documented in this file.

## [8.23.0](https://github.com/openvoxproject/openvox/tree/8.23.0) (2025-09-07)

[Full Changelog](https://github.com/openvoxproject/openvox/compare/8.22.0...8.23.0)

- This is our first release where MacOS and Windows agents are built entirely in GitHub Actions!
- MacOS x86_64 is now supported
- The MacOS agents now work on all currently supported MacOS versions (13, 14, and 15). No need for separate packages!
- The openvox-agent repo, which was the repo used for building the openvox-agent packages, has now been integrated into this openvox repo under the 'packaging' directory. This will allow us to have fewer steps in the build process and tag changes more cleanly, rather than having to tag two separate repos. Note that for releases prior to this one, the changelog in this file refers only to the changes to openvox itself and not packaging changes. For example, 8.22.1 was released to fix an unintentional service renaming issue and details are in the openvox-agent repo. At some point, we may try to integrate the two changelogs.
- This release contains a large number of dependencies bumps. Most are not security related, but many dependencies were lagging for a long time. See [this PR](https://github.com/OpenVoxProject/puppet-runtime/pull/35) for details.
- A patch for Augeas to address [CVE-2025-2588](https://github.com/advisories/GHSA-hxwj-c5vw-fwgp)

**Implemented enhancements:**

- \[Feature request\]: Package PDK [\#166](https://github.com/OpenVoxProject/openvox/issues/166)
- Respect systemd's RUNTIME\_DIRECTORY environment variable [\#165](https://github.com/OpenVoxProject/openvox/pull/165) ([ekohl](https://github.com/ekohl))

**Fixed bugs:**

- treat windows service accounts as case insensitive [\#172](https://github.com/OpenVoxProject/openvox/pull/172) ([binford2k](https://github.com/binford2k))
- Ensure confdir exists [\#171](https://github.com/OpenVoxProject/openvox/pull/171) ([binford2k](https://github.com/binford2k))

**Merged pull requests:**

- Promote puppet-runtime 2025.09.04.1 [\#191](https://github.com/OpenVoxProject/openvox/pull/191) ([nmburgan](https://github.com/nmburgan))
- Merge openvox-agent vanagon repo [\#186](https://github.com/OpenVoxProject/openvox/pull/186) ([austb](https://github.com/austb))

## [8.22.0](https://github.com/openvoxproject/openvox/tree/8.22.0) (2025-08-23)

[Full Changelog](https://github.com/openvoxproject/openvox/compare/8.21.1...8.22.0)

## [8.21.1](https://github.com/openvoxproject/openvox/tree/8.21.1) (2025-07-23)

[Full Changelog](https://github.com/openvoxproject/openvox/compare/8.21.0...8.21.1)

**Fixed bugs:**

- Make passing invalid options to install.rb fatal [\#156](https://github.com/OpenVoxProject/openvox/pull/156) ([ekohl](https://github.com/ekohl))

**Merged pull requests:**

- Revert "Mark some failing 8.3 Windows tests as pending" [\#159](https://github.com/OpenVoxProject/openvox/pull/159) ([ekohl](https://github.com/ekohl))
- \(maint\) Drop debian-10 from testing matrix [\#152](https://github.com/OpenVoxProject/openvox/pull/152) ([jpartlow](https://github.com/jpartlow))

## [8.21.0](https://github.com/openvoxproject/openvox/tree/8.21.0) (2025-07-09)

[Full Changelog](https://github.com/openvoxproject/openvox/compare/8.20.0...8.21.0)

**Implemented enhancements:**

- Remove facter from install.rb [\#147](https://github.com/OpenVoxProject/openvox/pull/147) ([ekohl](https://github.com/ekohl))

## [8.20.0](https://github.com/openvoxproject/openvox/tree/8.20.0) (2025-06-27)

[Full Changelog](https://github.com/openvoxproject/openvox/compare/8.19.2...8.20.0)

**Implemented enhancements:**

- Switch from facter to openfact [\#142](https://github.com/OpenVoxProject/openvox/pull/142) ([smortex](https://github.com/smortex))
- \(PUP-12083\) Update soft limit warning for fact value & name length [\#137](https://github.com/OpenVoxProject/openvox/pull/137) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- Maintain consistent JSON formatting  [\#132](https://github.com/OpenVoxProject/openvox/pull/132) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- cleanup gem metadata after Perforce-\>OpenVoxProject migration [\#140](https://github.com/OpenVoxProject/openvox/pull/140) ([smortex](https://github.com/smortex))

## [8.19.2](https://github.com/openvoxproject/openvox/tree/8.19.2) (2025-06-06)

[Full Changelog](https://github.com/openvoxproject/openvox/compare/8.19.1...8.19.2)

**Fixed bugs:**

- server\_facts: Switch implementation-\>serverimplementation [\#107](https://github.com/OpenVoxProject/openvox/pull/107) ([binford2k](https://github.com/binford2k))
- Reflect Ruby 3.4 stack trace changes [\#100](https://github.com/OpenVoxProject/openvox/pull/100) ([ekohl](https://github.com/ekohl))
- Add base64 as gem dependencies for Ruby 3.4 [\#98](https://github.com/OpenVoxProject/openvox/pull/98) ([ekohl](https://github.com/ekohl))
- Add racc gem dependency [\#89](https://github.com/OpenVoxProject/openvox/pull/89) ([ekohl](https://github.com/ekohl))

## [8.19.1](https://github.com/openvoxproject/openvox/tree/8.19.1) (2025-06-03)

[Full Changelog](https://github.com/openvoxproject/openvox/compare/8.19.0...8.19.1)

**Fixed bugs:**

- Fix invalid gemspec in AIO package [\#91](https://github.com/OpenVoxProject/openvox/pull/91) ([smortex](https://github.com/smortex))

## [8.19.0](https://github.com/openvoxproject/openvox/tree/8.19.0) (2025-05-30)

[Full Changelog](https://github.com/openvoxproject/openvox/compare/8.18.1...8.19.0)

**Implemented enhancements:**

- Add `implementation` fact to agent and server. [\#63](https://github.com/OpenVoxProject/openvox/pull/63) ([ffrank](https://github.com/ffrank))

**Fixed bugs:**

- Replace `erase` with `remove`, since it's no longer supported with DNF5 [\#68](https://github.com/OpenVoxProject/openvox/pull/68) ([Stricken1670](https://github.com/Stricken1670))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
