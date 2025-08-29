#!/bin/bash

set -e

source "$(dirname $0)/../../helpers.sh"

USAGE="USAGE: $0 <master-vm1> <master-vm2> <agent-version> <server-version> <puppetdb-version> [<collection>]"

master_vm1="$1"
master_vm2="$2"
agent_version="$3"
server_version="$4"
puppetdb_version="$5"
collection="${6:-$(guess_puppet_collection_for $agent_version)}"

if [[ -z "${master_vm1}" || -z "${master_vm2}" || -z "${agent_version}" || -z "${server_version}" || -z "${puppetdb_version}}" ]]; then
  echo "${USAGE}"
  exit 1
fi

echo "Running the script with the following master hosts ..."
echo "  Master with PuppetDB installed via. module (master1): ${master_vm1}"
echo "  Master with PuppetDB installed via. package (master2): ${master_vm2}"
echo ""

echo "Running the script with the following package versions ..."
echo "  puppet-agent version: ${agent_version}"
echo "  puppetserver version: ${server_version}"
echo "  puppetdb version: ${puppetdb_version}"
echo ""

function identify_master() {
  local master_vm="$1"

  if [[ "${master_vm}" == "${master_vm1}" ]]; then
    echo "master1"
  else
    echo "master2"
  fi
}

echo "STEP: Install puppetserver and puppet-agent on both masters"

for master_vm in ${master_vm1} ${master_vm2}; do
  which_master=`identify_master ${master_vm}`
  on_master ${master_vm} "rpm -Uvh http://yum.puppetlabs.com/${collection}-release-el-7.noarch.rpm --force"

  echo "STEP: Install puppet-agent on ${which_master}"
  on_master ${master_vm} "rpm --quiet --query puppet-agent-${agent_version} || yum install -y puppet-agent-${agent_version}"
  on_master ${master_vm} "echo \`facter networking.ip\` puppet > /etc/hosts"
  echo ""
  echo ""

  echo "STEP: Install puppetserver on ${which_master}"
  on_master ${master_vm} "rpm --quiet --query puppetserver-${server_version} || yum install -y puppetserver-${server_version}"
  on_master ${master_vm} "puppet resource service puppetserver ensure=running"
  set +e
  on_master ${master_vm} "puppet agent -t"
  exitcode=$?
  set -e
  if [[ "$exitcode" -ne 0 && "$exitcode" -ne 2 ]]; then
    echo "FAILED to run puppet on master"
    exit 1
  fi
  echo ""
  echo ""
done

install_puppetdb_from_module "${master_vm1}"
install_puppetdb_from_package "${master_vm2}" "repo" ${collection}

for master_vm in ${master_vm1} ${master_vm2}; do
  which_master=`identify_master ${master_vm}`
  enable_firewall="puppet apply -e \"firewall { '100 allow http and https access': dport => [80, 443, 8140], proto => tcp, action => accept, }\""

  echo "STEP: Open firewall for puppetserver on ${which_master}"
  if [[ "${master_vm}" == "${master_vm1}" ]]; then
    on_master "${master_vm}" "${enable_firewall}"
  else
    # Per the docs, this is expected to fail on the master that has PuppetDB
    # installed from the package.
    set +e
    on_master "${master_vm}" "${enable_firewall}"
    set -e
  fi
  echo ""
  echo ""
done

for master_vm in ${master_vm1} ${master_vm2}; do
  which_master=`identify_master ${master_vm}`
  SEMANTIC_VERSION_RE="[0-9]+\.[0-9]+\.[0-9]+-[0-9]+"
  REQUIRED_PACKAGES="${collection}-release-${SEMANTIC_VERSION_RE}\.el7\.noarch puppet-agent-${SEMANTIC_VERSION_RE}\.el7\.x86_64 puppetserver-${SEMANTIC_VERSION_RE}\.el7\.noarch puppetdb-${SEMANTIC_VERSION_RE}\.el7\.noarch puppetdb-termini-${SEMANTIC_VERSION_RE}\.el7\.noarch"

  echo "STEP: Verify that the required puppet packages are installed on ${which_master}!"
  grep_results=`on_master "${master_vm}" "rpm -qa | grep puppet"`
  for required_package in  ${REQUIRED_PACKAGES}; do

    set +e
    concrete_package=`echo "${grep_results}" | grep -E  "${required_package}"`
    set -e
    if [[ -n "${concrete_package}" ]]; then
      echo "The required puppet package is present on ${which_master} as ${concrete_package}!"
    else
      echo "The required puppet package ${required_package} is not found on ${which_master}!"
      echo ""
      echo "### EXPECTED TO MATCH: ####"
      echo "${REQUIRED_PACKAGES}" | tr " " "\n"
      echo "###"
      echo ""
      echo "### ACTUAL: ###"
      echo "${grep_results}"
      echo "###"
      echo ""
      echo "Failing the tests ..."
      exit 1
    fi
  done
  echo ""
  echo ""
done
