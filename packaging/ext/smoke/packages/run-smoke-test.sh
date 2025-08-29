#!/bin/bash

set -e
source "$(dirname $0)/../helpers.sh"

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee -i "$(dirname $0)/../puppet-agent-${3}-smoke-test-packages-output.txt")

# Include stderr
exec 2>&1

USAGE="USAGE: $0 <master-vm> <agent-vm> <agent-version> <server-version> <puppetdb-version> [<collection>]"
domain=".delivery.puppetlabs.net"

master_vm="$1"
agent_vm="$2"
agent_version="$3"
server_version="$4"
puppetdb_version="$5"

if [[ -z "${master_vm}" || -z "${agent_vm}" || -z "${agent_version}" || \
      -z "${server_version}" || -z "${puppetdb_version}" ]]; then
  echo "${USAGE}"
  exit 1
fi

master_vm=$(hostname_with_domain $master_vm)
agent_vm=$(hostname_with_domain $agent_vm)
collection="${6:-$(guess_puppet_collection_for $agent_version)}"

echo "##### master_vm = ${master_vm}"
echo "##### agent_vm = ${agent_vm}"
echo "##### agent_version = ${agent_version}"
echo "##### server_version = ${server_version}"
echo "##### puppetdb_version = ${puppetdb_version}"
echo "##### collection = ${collection}"
echo ""
echo "#### Setting up master..."
$(dirname $0)/steps/setup-master.sh ${master_vm} ${agent_version} ${server_version} ${puppetdb_version} ${collection}

echo "#### Setting up agent..."
$(dirname $0)/../steps/setup-agent.sh ${master_vm} ${agent_vm} ${agent_version} "package" ${collection}

echo "#### Running validation"
$(dirname $0)/../steps/run-validation-tests.sh ${master_vm} ${agent_vm}

echo "#### Sending parameters to Artifactory for use by repo smoke test"
versions_file=${agent_version}.json
version_data="{
                \"puppetserver\":\"$server_version\",
                \"puppetdb\":\"$puppetdb_version\"
              }"
echo $version_data > $versions_file
curl -T $versions_file "https://artifactory.delivery.puppetlabs.net/artifactory/scratchpad__local/puppet-agent-version-compatibility/${versions_file}"
rm $versions_file

echo
echo "All done!"
