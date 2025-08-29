#!/bin/bash

function on_host() {
  host="$1"
  label="$2"
  cmd="$3"
  suppress="$4"

  echo ""
  echo "### DEBUG: Running the following command on the ${label}"
  echo "  ${cmd}"
  echo "###"

  if [[ -z "${VANAGON_SSH_KEY}" ]]; then
    identity=''
  else
    identity="-i ${VANAGON_SSH_KEY}"
  fi

  echo $identity

  if [[ -z "${suppress}" || "${suppress}" == "false" ]]; then
    ssh $identity -oStrictHostKeyChecking=no root@${host} "${cmd}" 2>/dev/null
  else
    ssh $identity -oStrictHostKeyChecking=no root@${host} "${cmd}" 2>/dev/null 1>/dev/null
  fi
}

function on_master() {
  host="$1"
  cmd="$2"
  suppress="$3"
  on_host "${host}" "master" "${cmd}" "${suppress}"
}

function on_agent() {
  host="$1"
  cmd="$2"
  suppress="$3"
  on_host "${host}" "agent" "${cmd}" "${suppress}"
}

function start_puppetdb() {
  local master_vm="$1"

  if [[ "$type" = "dev" ]]; then
    local which_master="${master_vm}"
  elif [[ "$type" = "repo" ]]; then
    local which_master=`identify_master ${master_vm}`
  fi

  echo "STEP: Start PuppetDB and point it to puppetserver"
  on_master ${master_vm} "puppet resource service puppetdb ensure=running enable=true"
  local puppetdb_conf="/etc/puppetlabs/puppet/puppetdb.conf"
  on_master ${master_vm} "echo [main] > ${puppetdb_conf}"
  on_master ${master_vm} "echo server_urls = https://\`facter networking.fqdn\`:8081 >> ${puppetdb_conf}"
  echo ""
  echo ""

  echo "STEP: Adding PuppetDB to storeconfigs and reports settings in puppet.conf"
  local puppet_conf="/etc/puppetlabs/puppet/puppet.conf"
  on_master ${master_vm} "echo storeconfigs = true >> ${puppet_conf}"
  on_master ${master_vm} "echo storeconfigs_backend = puppetdb >> ${puppet_conf}"
  on_master ${master_vm} "echo reports = store,puppetdb >> ${puppet_conf}"
  echo ""
  echo ""

  echo "STEP: Creating route_file with puppetdb terminus for facts"
  local route_file
  route_file=`on_master ${master_vm} "puppet config print route_file" | tail -n 1`
  on_master ${master_vm} "echo --- > ${route_file}"
  on_master ${master_vm} "echo master: >> ${route_file}"
  on_master ${master_vm} "echo \"  facts:\" >> ${route_file}"
  on_master ${master_vm} "echo \"    terminus: puppetdb\" >> ${route_file}"
  on_master ${master_vm} "echo \"    cache: yaml\" >> ${route_file}"
  echo ""
  echo ""

  echo "STEP: Setting ownership on everything"
  on_master ${master_vm} 'chown -R puppet:puppet `puppet config print confdir`'
  echo ""
  echo ""

  echo "STEP: Restart puppetserver and perform a puppet run to ensure that facts and reports are sent to PuppetDB"
  on_master ${master_vm} "puppet resource service puppetserver ensure=stopped"
  on_master ${master_vm} "puppet resource service puppetserver ensure=running"
  set +e
  on_master ${master_vm} "puppet agent -t"
  local exit_code="$?"
  set -e
  if [[ "${exit_code}" -ne 2 && "${exit_code}" -ne 0 ]]; then
    echo "Failed to start-up PuppetDB on ${which_master}!"
    echo "Exiting the script with a failure ..."
    exit 1
  fi
  on_master ${master_vm} "grep 'replace facts' /var/log/puppetlabs/puppetdb/puppetdb.log && echo '### Facts successfully sent to PuppetDB ###'"
  on_master ${master_vm} "grep 'replace catalog' /var/log/puppetlabs/puppetdb/puppetdb.log && echo '### Reports successfully sent to PuppetDB ###'"
  echo ""
  echo ""
}


function install_puppetdb_from_module() {
  local master_vm="$1"

  if [[ "$type" = "dev" ]]; then
    local which_master="${master_vm}"
  elif [[ "$type" = "repo" ]]; then
    local which_master=`identify_master ${master_vm}`
  fi

  echo "STEP: Install PuppetDB from the module on ${which_master}!"
  on_master ${master_vm} "yum install -y ca-certificates"
  on_master ${master_vm} "puppet module install puppetlabs-puppetdb"
  local site_pp="/etc/puppetlabs/code/environments/production/manifests/site.pp"
  FILE="node '\`facter networking.fqdn\`' {
    class { 'puppetdb::globals':
    version => '${puppetdb_version}'
    }
  class { 'puppetdb':
    manage_firewall => false
  }
  include puppetdb::master::config
  }
  node default {
    notify { 'hello': message => 'hello world' }
  }"
  on_master ${master_vm} "echo \"$FILE\" > ${site_pp}"
  # puppet agent -t returns an exit code of 2 if changes are successfully applied
  set +e
  on_master ${master_vm} "puppet agent -t"
  local exit_code="$?"
  set -e
  if [[ "${exit_code}" -ne 2 && "${exit_code}" -ne 0 ]]; then
    echo "Failed to install PuppetDB from the module on ${which_master}!"
    echo "Exiting the script with a failure ..."
    exit 1
  fi
  echo ""
  echo ""

  start_puppetdb ${master_vm}
  echo "Finished installing PuppetDB via. the module on ${which_master}!"
  echo ""
  echo ""
}


function install_puppetdb_from_package() {
  local master_vm="$1"
  # Either "dev" (packages on builds.delivery.puppetlabs.net) or "repo" (packages released).
  local type="$2"
  local collection="$3"

  if [[ "$type" = "dev" ]]; then
    local which_master="${master_vm}"
  elif [[ "$type" = "repo" ]]; then
    local which_master=`identify_master ${master_vm}`
  fi

  echo "STEP: Install PuppetDB from package on ${which_master}!"

  # FIXME: Parametrize on postgres version?
  # TODO: Fix once posgres fixes upstream:
  # the pgdb package installs the postgress repositories. Postgres repositories make the assumption that the $releasever on Rehat 7 is "7" which is not corrent. 
  # The $releasever on Rehat 7 Server is "7Server" causing the postgresql installtion to fail because //download.postgresql.org/pub/repos/yum/12/redhat/rhel-7Server-x86_64/repodata/repomd.xml does not exist.
  local yum_cmd="yum --releasever=7"

  echo "STEP: Set-up postgresql 11 to use with PuppetDB"
  on_master ${master_vm} "yum install -y ca-certificates"
  on_master ${master_vm} "${yum_cmd} install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
  on_master ${master_vm} "rpm --query --quiet postgresql14-server || ${yum_cmd} install -y postgresql14-server"
  on_master ${master_vm} "rpm --query --quiet postgresql14-contrib || ${yum_cmd} install -y postgresql14-contrib"
  on_master ${master_vm} "puppet resource service postgresql-14 ensure=stopped"
  on_master ${master_vm} "rm -rf /var/lib/pgsql/11/data && /usr/pgsql-14/bin/postgresql-14-setup initdb"
  on_master ${master_vm} "puppet resource service postgresql-14 ensure=running enable=true"

  #After postgress has been installed we need to remove the postgress repo or else other yum install commands will fail.
  on_master ${master_vm} "${yum_cmd} remove -y pgdg-redhat-repo-42.0-24.noarch"

  # Enters 'puppet' as the password.
  on_master ${master_vm} "runuser -l postgres -c '(echo puppet && echo puppet) | createuser -DRSP puppetdb'"
  on_master ${master_vm} "runuser -l postgres -c 'createdb -E UTF8 -O puppetdb puppetdb'"
  on_master ${master_vm} "runuser -l postgres -c \"psql puppetdb -c 'create extension pg_trgm'\""

  # Edit pg_hba.conf to use md5 authentication for all DB connections
  local pg_hba_path
  pg_hba_path=`on_master ${master_vm} "find / -name *pg_hba.conf | head -n 1" | tail -n 1`
  on_master ${master_vm} "echo local all all md5 > ${pg_hba_path}"
  on_master ${master_vm} "echo host all all 127.0.0.1/32 md5 >> ${pg_hba_path}"
  on_master ${master_vm} "echo host all all ::1/128 md5 >> ${pg_hba_path}"

  # Restart postgresql and ensure that the puppetdb user can authenticate
  # (you will need to enter the password then hit exit)
  on_master ${master_vm} 'service postgresql-14 restart'
  # Should list puppetdb as one of the users
  on_master ${master_vm} "echo puppet | psql -h localhost puppetdb puppetdb -c '\\du' | grep puppetdb"
  echo ""
  echo ""

  # Install the PuppetDB package
  echo "STEP: Installing the PuppetDB package ..."
  if [[ "$type" = "dev" ]]; then
    on_master ${master_vm} "curl -f -O http://builds.delivery.puppetlabs.net/puppetdb/${puppetdb_version}/artifacts/el/7/${collection}/x86_64/puppetdb-termini-${puppetdb_version}-1.el7.noarch.rpm"
    on_master ${master_vm} "curl -f -O http://builds.delivery.puppetlabs.net/puppetdb/${puppetdb_version}/artifacts/el/7/${collection}/x86_64/puppetdb-${puppetdb_version}-1.el7.noarch.rpm"
    on_master ${master_vm} "rpm -ivh puppetdb-${puppetdb_version}-1.el7.noarch.rpm puppetdb-termini-${puppetdb_version}-1.el7.noarch.rpm"
  elif [[ "$type" = "repo" ]]; then
    on_master ${master_vm} "rpm --quiet --query puppetdb-${puppetdb_version} || yum install -y puppetdb-${puppetdb_version}"
    on_master ${master_vm} "rpm --quiet --query puppetdb-termini-${puppetdb_version} || yum install -y puppetdb-termini-${puppetdb_version}"
  else
    echo "Unexpected type '${type}' supplied to install_puppetdb_from_package"
    exit 1
  fi
  echo ""
  echo ""

  # Configure PuppetDB
  echo "STEP: Configuring the PuppetDB package ..."
  local puppetdb_database_ini="/etc/puppetlabs/puppetdb/conf.d/database.ini"
  on_master ${master_vm} "echo subname = //localhost:5432/puppetdb >> ${puppetdb_database_ini}"
  on_master ${master_vm} "echo username = puppetdb >> ${puppetdb_database_ini}"
  on_master ${master_vm} "echo password = puppet >> ${puppetdb_database_ini}"
  echo ""
  echo ""

  start_puppetdb ${master_vm}
  echo "Finished installing PuppetDB via. the package on ${which_master}!"
  echo ""
  echo ""
}

# Given a hostname or FQDN ($1), append a domain ($2, defaults to
# '.delivery.puppetlabs.net') to form an FQDN if necessary
function hostname_with_domain() {
  host=$1
  domain=${2:-.delivery.puppetlabs.net}
  if [[ ! $host == *.* ]]; then
    host="$host$domain"
  fi
  echo $host
}

# Guesses the puppet collection based on a version of puppet-agent ($1)
function guess_puppet_collection_for() {
  if [[ $1 =~ ^[0-9] ]]; then
    echo "puppet${1:0:1}"
  else
    echo "ERROR: Couldn't determine a puppet collection based on the puppet-agent version '${1}'"
    exit 1
  fi
}
