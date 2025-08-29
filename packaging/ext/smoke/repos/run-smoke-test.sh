#!/bin/bash

set -e
source "$(dirname $0)/../helpers.sh"

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee -i "$(dirname $0)/../puppet-agent-${5}-smoke-test-repos-output.txt")

# Include stderr
exec 2>&1

USAGE="USAGE: $0 <master-vm1> <master-vm2> <agent-vm1> <agent-vm2> <agent-version> <server-version> <puppetdb-version> [<collection>]"
domain=".delivery.puppetlabs.net"

master_vm1="$1"
master_vm2="$2"
agent_vm1="$3"
agent_vm2="$4"
agent_version="$5"
server_version="$6"
puppetdb_version="$7"

if [[ -z "${master_vm1}" || -z "${master_vm2}" || -z "${agent_vm1}" || \
      -z "${agent_vm2}" || -z "${agent_version}" || -z "${server_version}" || \
      -z "${puppetdb_version}" ]]; then
  echo "${USAGE}"
  exit 1
fi

master_vm1=$(hostname_with_domain $master_vm1)
master_vm2=$(hostname_with_domain $master_vm2)
agent_vm1=$(hostname_with_domain $agent_vm1)
agent_vm2=$(hostname_with_domain $agent_vm2)
collection="${8:-$(guess_puppet_collection_for $agent_version)}"

echo "##### master_vm1 = ${master_vm1}"
echo "##### master_vm2 = ${master_vm2}"
echo "##### agent_vm1 = ${agent_vm1}"
echo "##### agent_vm2 = ${agent_vm2}"
echo "##### agent_version = ${agent_version}"
echo "##### server_version = ${server_version}"
echo "##### puppetdb_version = ${puppetdb_version}"
echo "##### collection = ${collection}"
echo ""
echo "##### Setting up masters..."
$(dirname $0)/steps/setup-masters.sh ${master_vm1} ${master_vm2} ${agent_version} ${server_version} ${puppetdb_version} ${collection}

# One agent starts with master 1, one agent starts with master 2
echo "##### Master 1 (PuppetDB Module) + Agent 1"
$(dirname $0)/../steps/setup-agent.sh          ${master_vm1} ${agent_vm1} ${agent_version} "repo" ${collection}
$(dirname $0)/../steps/run-validation-tests.sh ${master_vm1} ${agent_vm1}
echo "##### Master 2 (PuppetDB Package) + Agent 2"
$(dirname $0)/../steps/setup-agent.sh          ${master_vm2} ${agent_vm2} ${agent_version} "repo" ${collection}
$(dirname $0)/../steps/run-validation-tests.sh ${master_vm2} ${agent_vm2}

echo "All done!"
