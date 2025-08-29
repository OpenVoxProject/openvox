# Github Actions Acceptance Workflow

[acceptance.yaml](.github/workflows/acceptance.yaml)

This is a manual pipeline that can be triggered from the Actions tab
of the GitHub repository. It runs the Beaker acceptance tests against
either a pre-release build from
https://artifacts.overlookinfratech.com, or released packages from the
overlookinfratech.com repos.

The pipeline makes use of nested virtualization to standup an agent
of a given OS platform for the runner to run Beaker against. A matrix
strategy builds out jobs for different os/version combinations.

## Internals

The workflow makes use of a composite action currently living in a
Bolt module
[kvm_automation_tooling](https://github.com/jpartlow/kvm_automation_tooling/blob/main/action.yaml).

The action preps libvirt on the runner, installs Bolt and runs a
[kvm_automation_tooling::standup_cluster](https://github.com/jpartlow/kvm_automation_tooling/blob/main/plans/standup_cluster.pp)
plan which makes use of Terraform to generate a set of vms, set up
ssh access and install the chose openvox-agent package.

Then the workflow sets up ruby/beaker per the acceptance/Gemfile and
runs another
[kvm_automation_tooling::dev::generate_beaker_hosts_file](https://github.com/jpartlow/kvm_automation_tooling/blob/main/plans/dev/generate_beaker_hosts_file.pp)
plan to set up the beaker hosts file. And then runs beaker.

Note acceptance/Rakefile is not used in this workflow. That process
relies on tasks provided by beaker-puppet which are tied to Perforce
internals and repositories.

Instead the kvm_automation_tooling plans installs openvox-agent
packages using another Bolt module
[openvox_bootstrap](https://github.com/jpartlow/openvox_bootstrap/).
This module has an install task which servers the same purpose as the
puppet_agent module install task: initial installation of the agent.
The openvox_bootstrap module is configured to use the voxpupuli
repositories.

The module also has an
[openvox_bootstrap::install_build_artifact](https://github.com/jpartlow/openvox_bootstrap/blob/main/tasks/install_build_artifact.json)
task, which is what is used to install pre-release builds for testing
in the pipeline.
