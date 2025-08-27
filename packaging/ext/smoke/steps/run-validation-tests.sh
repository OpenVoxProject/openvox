#!/bin/bash

set -e

function on_host() {
  host="$1"
  cmd="$2"
  suppress="$3"

  if [[ -z "${VANAGON_SSH_KEY}" ]]; then
    identity=''
  else
    identity="-i ${VANAGON_SSH_KEY}"
  fi

  if [[ -z "${suppress}" || "${suppress}" == "false" ]]; then
    ssh $identity -oStrictHostKeyChecking=no root@${host} "${cmd}" 2>/dev/null
  else
    ssh $identity -oStrictHostKeyChecking=no root@${host} "${cmd}" 2>/dev/null 1>/dev/null
  fi
}

function on_master() {
  cmd="$1"
  suppress="$2"

  on_host ${master_vm} "${cmd}" "${suppress}"
}

function on_agent() {
  cmd="$1"
  suppress="$2"

  on_host ${agent_vm} "${cmd}" "${suppress}"
}

function run_dataset_count_test() {
  test_name="$1"
  endpoint="$2"

  echo "### TEST: ${test_name} ###"
  result=`on_master "curl -f -G http://localhost:8080/pdb/query/v4/${endpoint} | /bin/jq \". | length\""`
  echo "Result is: ${result}"
  if [[ "${result}" == "2" || "${result}" == "3" ]]; then
    echo "### RESULT: SUCCESS ###"
  else
    echo "### RESULT: FAIL ###"
    exit 1
  fi
  echo ""
  echo ""
}


USAGE="USAGE: $0 <master-vm> <agent-vm>"

master_vm="$1"
agent_vm="$2"

if [[ -z "${master_vm}" || -z "${agent_vm}" ]]; then
  echo "${USAGE}"
  exit 1
fi

echo "Running the product validation tests with the following master-agent pair ..."
echo "  MASTER: ${master_vm}"
echo "  AGENT: ${agent_vm}"
echo ""

echo "Installing jq for use in script"
on_master "wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /bin/jq; chmod +x /bin/jq"

### TESTS ###

echo "### TEST: Query PuppetDB for external node data ###"
result=`on_master "curl -f -X POST http://localhost:8080/pdb/query/v4/nodes -H 'Content-Type:application/json' -d '{\"query\":[\"=\",\"certname\",\"${agent_vm}\"]}' | /bin/jq ."`
if [[ "${result}" =~ ${agent_vm} ]]; then
  echo "### RESULT: SUCCESS ###"
else
  echo "### RESULT: FAIL ###"
fi
echo ${result}
echo ""
echo ""



echo "### TEST: Query PuppetDB for external fact data ###"
on_agent "echo foo=bar > /opt/puppetlabs/facter/facts.d/test.txt" "true"
set +e
on_agent "puppet agent -t" "true"
set -e
result=`on_master "curl -f -X POST http://localhost:8080/pdb/query/v4/facts/foo -H 'Content-Type:application/json' -d '{\"query\":[\"=\",\"certname\",\"${agent_vm}\"]}' | /bin/jq ."`
if [[ "${result}" =~ ${agent_vm} ]]; then
  echo "### RESULT: SUCCESS ###"
else
  echo "### RESULT: FAIL ###"
  exit 1
fi
echo ""
echo ""

run_dataset_count_test "Ensure node count is equal to number of agents" "nodes"
run_dataset_count_test "Ensure factset count is equal to number of agents" "factsets"
run_dataset_count_test "Ensure catalog count is equal to number of agents" "catalogs"

exitcode=0
for host in ${master_vm} ${agent_vm}; do
  echo "### TEST: Ensure that reports are present for ${host} ###"
  result=`on_master "curl -f -X POST http://localhost:8080/pdb/query/v4/reports -H 'Content-Type:application/json' -d '{\"query\":[\"=\",\"certname\",\"${host}\"]}' | jq \". | length\""`
  echo ${result}
  if [[ "${result}" -gt 0 ]]; then
    echo "### RESULT: SUCCESS ###"
  else
    echo "### RESULT: FAIL ###"
    exitcode=1
  fi
  echo ""
  echo ""
done
exit ${exitcode}
