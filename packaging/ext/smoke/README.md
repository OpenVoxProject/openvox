## Release Validation

These scripts will help with steps leading up to a new puppet-agent
release.

### Overview

This folder contains scripts to help with two smoke testing stages of
the release process.

#### Manually smoke test platform components installed from packages

To run these smoke tests, check out 2 redhat-7-x86_64 VMs.
Then run the `packages/run-smoke-test.sh` script as follows:

```
./packages/run-smoke-test.sh <VM> <VM> <agent_version> <server_version> <puppetdb_version>

```

#### Manually smoke test platform components installed from shared respository

These tests will ensure that released packages can run. There are two
scenarios, one where puppetdb is installed via packages and one where
puppetdb is installed via module.

To run these smoke tests, check out 4 redhat-7-x86_64 VMs.
Then run the `repos/run-smoke-test.sh` script as follows:

```
./repos/run-smoke-test.sh <VM> <VM> <VM> <VM> <agent_version> <server_version> <puppetdb_version>
```
