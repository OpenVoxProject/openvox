The Puppet Agent
===
 * Overview
 * Runtime requirements
 * Building puppet-agent
 * Branches in puppet-agent
 * License
 * Code Owners
 * Running Tests
 * Github Actions

Overview
---
The puppet agent is a collection of software that is required for puppet and
its dependencies to run.
This includes [puppet](https://github.com/OpenVoxProject/openvox), [facter](https://github.com/OpenVoxProject/openfact), and other Puppet software, but also vendored dependencies like ruby, curl, openssl, and more.

This repository contains configuration to build puppet-agent and the openfact gem for all of Puppet's supported platforms using [vanagon](https://github.com/OpenVoxProject/vanagon), a packaging utility.

The full list of software components built into the puppet agent and the openfact gem can be found in their [project definitions](configs/projects/), and each of the components has its own configuration in the [components directory](configs/components/).

Components that are not developed by Puppet (like ruby, curl, or openssl) are
built separately into a tarball and consumed here in the
[puppet-runtime](configs/components/puppet-runtime.rb) component. See the
[puppet-runtime](https://github.com/OpenVoxProject/puppet-runtime) project for more
information and a full list of the vendored dependencies it provides.

pxp-agent is built separately into a tarball and consumed here in the
[pxp-agent](configs/components/puppet-pxp-agent.rb) component. See the
[pxp-agent-vanagon](https://github.com/OpenVoxProject/pxp-agent-vanagon) project for more information.

Runtime Requirements
---
Ruby and [bundler](http://bundler.io/) are required to build puppet-agent. The
[Gemfile](Gemfile) specifies all of the necessary ruby libraries to build a
puppet-agent package.  Additionally, puppet-agent requires a VM to build within
for each desired package.

## Environment variables
#### VANAGON\_LOCATION
The location of Vanagon in the Gemfile can be overridden with the environment variable `VANAGON_LOCATION`. Can be set prior to `bundle install` or updated with `bundle update`.

* `0.3.14` - Specific tag from the Vanagon git repo
* `https://github.com/OpenVoxProject/vanagon#version` - Remote git location and version (can be a ref, branch or tag)
* `file:///workspace/vanagon` - Absolute file path
* `file://../vanagon` - File path relative to the project directory

#### DEV\_BUILD
By default, headers and other files that aren't needed in the final puppet-agent package will be removed as part of the [cleanup component](configs/components/cleanup.rb). If you'd like to keep these files in the finished package, set the `DEV_BUILD` environment variable to some non-empty value. Note that this will increase the size of the package considerably.

Building puppet-agent or the facter gem
---

If you wish to build puppet-agent yourself:

1. First, build the
   [puppet-runtime](https://github.com/OpenVoxProject/puppet-runtime) for your
   target platform and agent version.
2. Run `bundle install` to install required ruby dependencies.
3. Update the `location` and `version` in the [puppet-runtime
   component json file](configs/components/puppet-runtime.json) as follows:
   - `location` should be a file URL to your local puppet-runtime output
     directory, for example: `file:///home/you/puppet-runtime/output`
   - `version` should be the version of puppet-runtime that you built; You
     can find this value at the top level of the json metadata file produced by
     the build in your puppet-runtime output directory.
  4. You can disable the packaging of pxp-agent by setting `NO_PXP_AGENT` ENV variable.
  If you want to  build an agent package that also contains pxp-agent you need to
  update the `location` and `version` in the [pxp-agent
   component json file](configs/components/pxp-agent.json) as follows:
   - `location` should be a file URL to your local pxp-agent- output
     directory, for example: `file:///home/you/pxp-agent-vanagon/output`
   - `version` should be the version of pxp-agent that you built; You
     can find this value at the top level of the json metadata file produced by
     the build in your pxp-agent output directory.
  - You also may need to change the source URIs for some other components. We
    recognize this is less than ideal at this point, but we wanted to err on
    the side of getting this work out in public rather than having everything
    perfect. If you have your own mirror of the components of puppet-agent, you
    can also use a rewrite rule. See the [Vanagon
    README](https://github.com/OpenVoxProject/vanagon/blob/master/examples/projects/project.rb#L48)
    for an example.
5. Now use vanagon to build the puppet-agent. Run the following:

   ```sh
   bundle exec vanagon build <project-name> <platform> <vm-hostname>
   ```

   Where:
   - project name is a project from [configs/projects](configs/projects) (this can be `puppet-agent`),
   - platform is a platform supported by vanagon and defined in the
     [configs/platforms](configs/platforms/) directory (for example,
     `el-7-x86_64`), and
   - the vm hostname is the hostname of a vm matching the desired platform. The
     current user must be able to ssh into that vm as root (vanagon has facilities
     to provide an ssh key beyond what is listed in .ssh/config).

Branches in puppet-agent
---

Tracking branch (main + stable):
  * some components may reference tags if they’re slow moving (ruby, openssl)
  * some components reference SHAs promoted by a CI pipeline (generally puppet-agent#main pipelines track components' main branches, and likewise for stable)

Guidelines on Merging Between Branches
* stable should be merged to main regularly (e.g. per commit), as is done for component repos; no PR needed
* main should be merged to stable as-needed; typically this is done when a component merges its main to stable, and there are matching changes needed in puppet-agent

Generally, no PR is needed for routine merges from stable to main, but a PR is advised for other merges. Use your judgment of course, and put up a PR if you want review.

Note that for all merges from main or stable, the merge should pick up:
* changes outside of config/components
* changes that bumped to a tag inside config/components

But never:
* changes that bumped to a SHA inside config/components

Here's a sample snippet used for a stable -> main merge:

```
git merge --no-commit --no-ff stable
for i in {hiera,facter,puppet,pxp-agent,cpp-pcp-client}; do git checkout main -- configs/components/$i.json;done
git commit -m "(maint) Restore promoted components refs after merge from stable"
```

Issues
---
File issues in the [Puppet Agent project](https://github.com/OpenVoxProject/openvox-agent) on Github. Issues with individual components should be filed in their respective projects.

License
---
Puppet agent is licensed under the [Apache-2.0](LICENSE) license.

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
