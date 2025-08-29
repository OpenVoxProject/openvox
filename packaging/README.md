The OpenVox All-In-One (AIO) Agent
===
 * Overview
 * Runtime requirements
 * Building openvox-agent
 * Branches in openvox-agent
 * License
 * Code Owners
 * Running Tests
 * Github Actions

Overview
---
The OpenVox All-In-One (AIO) agent (aka openvox-agent) is a collection of software that is required for OpenVox and its dependencies to run.
This includes [openvox](https://github.com/OpenVoxProject/openvox), [openfact](https://github.com/OpenVoxProject/openfact), and other OpenVox software, but also vendored dependencies like ruby, curl, openssl, and more.

This part of the repository contains configuration to build the openvox-agent AIO package and the openfact gem for all of Puppet's supported platforms using [vanagon](https://github.com/OpenVoxProject/vanagon), a packaging utility.

The full list of software components built into the openvox agent and the openfact gem can be found in their [project definitions](configs/projects/), and each of the components has its own configuration in the [components directory](configs/components/).

Components that are not developed by Vox Pupuli (like ruby, curl, or openssl) are built separately into a tarball and consumed here in the
[puppet-runtime](configs/components/puppet-runtime.rb) component. See the
[puppet-runtime](https://github.com/OpenVoxProject/puppet-runtime) project for more
information and a full list of the vendored dependencies it provides.

Runtime Requirements
---
Ruby and [bundler](http://bundler.io/) are required to build openvox-agent. The
[Gemfile](Gemfile) specifies all of the necessary ruby libraries to build an
openvox-agent package.

## Environment variables
#### VANAGON\_LOCATION
The location of Vanagon in the Gemfile can be overridden with the environment variable `VANAGON_LOCATION`. Can be set prior to `bundle install` or updated with `bundle update`.

* `0.3.14` - Specific tag from the Vanagon git repo
* `https://github.com/OpenVoxProject/vanagon#version` - Remote git location and version (can be a ref, branch or tag)
* `file:///workspace/vanagon` - Absolute file path
* `file://../vanagon` - File path relative to the project directory

#### DEV\_BUILD
By default, headers and other files that aren't needed in the final openvox-agent package will be removed as part of the [cleanup component](configs/components/cleanup.rb). If you'd like to keep these files in the finished package, set the `DEV_BUILD` environment variable to some non-empty value. Note that this will increase the size of the package considerably.

Building openvox-agent or the openfact gem
---

If you wish to build openvox-agent yourself:

1. First, build the
   [puppet-runtime](https://github.com/OpenVoxProject/puppet-runtime) for your
   target platform and agent version.
2. Run `bundle install` to install required ruby dependencies.
3. Update the `location` and `version` in the [puppet-runtime component json file](configs/components/puppet-runtime.json) as follows:
   - `location` should be a file URL to your local puppet-runtime output
     directory, for example: `file:///home/you/puppet-runtime/output`
   - `version` should be the version of puppet-runtime that you built; You
     can find this value at the top level of the json metadata file produced by
     the build in your puppet-runtime output directory.
  - You also may need to change the source URIs for some other components. We
    recognize this is less than ideal at this point, but we wanted to err on
    the side of getting this work out in public rather than having everything
    perfect. If you have your own mirror of the components of openvox-agent, you
    can also use a rewrite rule. See the [Vanagon README](https://github.com/OpenVoxProject/vanagon/blob/master/examples/projects/project.rb#L48)
    for an example.
5. Now use vanagon to build the openvox-agent. Run the following:

   ```sh
   bundle exec vanagon build <project-name> <platform> --engine docker
   ```

   Where:
   - project name is a project from [configs/projects](configs/projects) (this can be `openvox-agent`),
   - platform is a platform supported by vanagon and defined in the
     [configs/platforms](configs/platforms/) directory (for example,
     `el-9-x86_64`), and

Issues
---
File issues in the [OpenVox repo](https://github.com/OpenVoxProject/openvox) on Github. Issues with individual components should be filed in their respective projects.

License
---
OpenVox agent is licensed under the [Apache-2.0](LICENSE) license.

Code Owners
---
See [CODEOWNERS](CODEOWNERS)

Running Tests
---
See [Acceptance README](acceptance/README.md)

Github Actions
---

PR validation runs a pair of GHA jobs that check commit messages and
run Rubocop (.github/workflows/checks.yml) via the Rakefile.

There is also a manual acceptance GHA pipeline that runs the Beaker
acceptance suite:
See [GHA_ACCEPTANCE](acceptance/GHA_ACCEPTANCE.md)
