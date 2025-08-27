#!/bin/bash

set -e

source "$(dirname $0)/../../helpers.sh"

USAGE="USAGE: $0 <master-vm> <agent-version> <server-version> <puppetdb-version> [collection-name]"

master_vm="$1"
agent_version="$2"
server_version="$3"
puppetdb_version="$4"
collection="${5:-$(guess_puppet_collection_for $agent_version)}"

if [[ -z "${master_vm}" || -z "${agent_version}" || -z "${server_version}" || -z "${puppetdb_version}}" ]]; then
  echo "${USAGE}"
  exit 1
fi

echo "Running the script with the following package versions ..."
echo "  puppet-agent version: ${agent_version}"
echo "  puppetserver version: ${server_version}"
echo "  puppetdb version: ${puppetdb_version}"
echo ""


## PUPPET AGENT

# Install puppet-agent package
echo "STEP (1): Install the puppet-agent package"
on_master ${master_vm} "curl -f -O http://builds.delivery.puppetlabs.net/puppet-agent/${agent_version}/artifacts/el/7/${collection}/x86_64/puppet-agent-${agent_version}-1.el7.x86_64.rpm"
on_master ${master_vm} "rpm -ivh puppet-agent-${agent_version}-1.el7.x86_64.rpm"
echo ""
echo ""

## PUPPETSERVER

# Install puppetserver
echo "STEP (2): Install puppetserver"
on_master ${master_vm} "curl -f -O http://builds.delivery.puppetlabs.net/puppetserver/${server_version}/artifacts/el/7/${collection}/x86_64/puppetserver-${server_version}-1.el7.noarch.rpm"
# FIXME: Might need to parametrize on Java?
on_master ${master_vm} "yum install -y java-11-openjdk-headless"
on_master ${master_vm} "rpm -ivh puppetserver-${server_version}-1.el7.noarch.rpm"
on_master ${master_vm} "echo \`facter networking.ip\` puppet > /etc/hosts"
echo ""
echo ""

# Start-up puppetserver and perform a puppet run to ensure that it is running
echo "STEP (3): Start-up puppetserver and perform a puppet run to ensure that it is running."
on_master ${master_vm} "puppet resource service puppetserver ensure=running"
on_master ${master_vm} "puppet agent -t"
echo ""
echo ""

## PUPPETDB

# Here we install puppetdb. To do so, we first set-up postgresql 11
# and use that to set-up the puppetdb user and database

# FIXME: Parametrize on postgres version?
echo "STEP (4): Set-up postgresql 11 to use with PuppetDB"
install_puppetdb_from_package ${master_vm} "dev" ${collection}

# Add PuppetDB to storeconfigs and reports settings in puppet.conf file
echo "STEP (5): Adding PuppetDB to storeconfigs and reports settings in puppet.conf"
puppet_conf="/etc/puppetlabs/puppet/puppet.conf"
on_master ${master_vm} "echo storeconfigs = true >> ${puppet_conf}"
on_master ${master_vm} "echo storeconfigs_backend = puppetdb >> ${puppet_conf}"
on_master ${master_vm} "echo reports = store,puppetdb >> ${puppet_conf}"
echo ""
echo ""

# Create route_file with puppetdb terminus for facts
echo "STEP (6): Creating route_file with puppetdb terminus for facts"
route_file=`on_master ${master_vm} "puppet config print route_file" | tail -n 1`
on_master ${master_vm} "echo --- > ${route_file}"
on_master ${master_vm} "echo master: >> ${route_file}"
on_master ${master_vm} "echo \"  facts:\" >> ${route_file}"
on_master ${master_vm} "echo \"    terminus: puppetdb\" >> ${route_file}"
on_master ${master_vm} "echo \"    cache: yaml\" >> ${route_file}"
echo ""
echo ""

# Set ownership on everything
echo "STEP (7): Setting ownership on everything"
on_master ${master_vm} 'chown -R puppet:puppet `puppet config print confdir`'
echo ""
echo ""

# Restart puppetserver and perform a puppet run to ensure that facts and
# reports are sent to PuppetDB
echo "STEP (8): Restart puppetserver and perform a puppet run to ensure that facts and reports are sent to PuppetDB"
on_master ${master_vm} "puppet resource service puppetserver ensure=stopped"
on_master ${master_vm} "puppet resource service puppetserver ensure=running"
on_master ${master_vm} "puppet agent -t"
on_master ${master_vm} "grep 'replace facts' /var/log/puppetlabs/puppetdb/puppetdb.log && echo '### Facts successfully sent to PuppetDB ###'"
on_master ${master_vm} "grep 'replace catalog' /var/log/puppetlabs/puppetdb/puppetdb.log && echo '### Reports successfully sent to PuppetDB ###'"
echo ""
echo ""

echo "Successfully set-up the master VM!"
