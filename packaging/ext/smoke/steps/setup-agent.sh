#!/bin/bash

set -e

source "$(dirname $0)/../helpers.sh"

USAGE="USAGE: $0 <master-vm> <agent-vm> <agent-version> <type> [<collection>]"

master_vm="$1"
agent_vm="$2"
agent_version="$3"
type="$4"

if [[ -z "${master_vm}" || -z "${agent_vm}" || -z "${agent_version}" || -z "${type}" ]]; then
  echo "${USAGE}"
  exit 1
fi

collection="${5:-$(guess_puppet_collection_for $agent_version})}"

function on_master() {
  cmd="$1"
  suppress="$2"
  on_host "${master_vm}" "master" "${cmd}" "${suppress}"
}

function on_agent() {
  cmd="$1"
  suppress="$2"
  on_host "${agent_vm}" "agent" "${cmd}" "${suppress}"
}

echo "Running the script with the following master-agent pair ..."
echo "  MASTER: ${master_vm}"
echo "  AGENT: ${agent_vm}"
echo ""

echo "Running the script with the following package versions ..."
echo "  puppet-agent version: ${agent_version}"
echo ""
echo "Running with type ${type}"
echo ""

echo "Clean out the agent's SSL directory so it forgets any old masters"

if [[ "$collection" =~ "puppet5" ]]; then
  on_master "puppet cert clean ${agent_vm} || true"
else
  # This produces an error when the cert can't be cleaned; we don't care
  on_master "puppetserver ca clean --certname ${agent_vm} || true"
fi

on_agent "rm -rf /etc/puppetlabs/puppet/ssl; sed -i '/puppet/d' /etc/hosts"

echo "STEP: Install the puppet-agent package"
master_ip=`on_master "facter networking.ip" | tail -n 1`
on_agent "echo ${master_ip} puppet >> /etc/hosts"
if [[ "${type}" = "repo" ]]; then
  on_agent "rpm -Uvh http://yum.puppetlabs.com/${collection}-release-el-7.noarch.rpm --force"
  on_agent "rpm --quiet --query puppet-agent-${agent_version} || yum install -y puppet-agent-${agent_version}"
elif [[ "${type}" = "package" ]]; then
  on_agent "curl -f -O http://builds.delivery.puppetlabs.net/puppet-agent/${agent_version}/artifacts/el/7/${collection}/x86_64/puppet-agent-${agent_version}-1.el7.x86_64.rpm"
  on_agent "rpm -ivh puppet-agent-${agent_version}-1.el7.x86_64.rpm"
else
  echo "Unrecognized type '${type}' supplied"
  exit 1
fi
echo ""
echo ""

# Run puppet to create SSL keys and have master sign them.
echo "STEP: Run puppet to create SSL keys, and have master sign them."
set +e
echo "Registering agent..."
on_agent "puppet agent -t"
set -e
echo "### DEBUG: Sleeping for 5 seconds to give some time for the agent cert to appear on the master ..."
sleep 5
# TODO check collection for puppet7
if [[ "${collection}" = "puppet5" ]]; then
  on_master "puppet cert sign --all"
else
  on_master "puppetserver ca sign --all"
fi
echo ""
echo ""

echo "STEP: Run puppet to get the catalog"
set +e
on_agent "puppet agent -t"
exitcode=$?
set -e
if [[ "$exitcode" = 0 || "$exitcode" = 2 ]]; then
  echo "Successfully set-up the agent VM!"
else
  echo "FAILED to set up the agent VM"
  exit 1
fi
echo ""
echo ""
