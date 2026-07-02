test_name "Agent should use set environment after running with specified environment" do
  require 'puppet/acceptance/environment_utils'
  extend Puppet::Acceptance::EnvironmentUtils

  tag 'audit:high',
      'server',
      'shard:group2' # For splitting out groups of tests for slow test runners

  # Remove all traces of the last used environment
  teardown do
    agents.each do |agent|
      on(agent, puppet('config print lastrunfile')) do |command_result|
        agent.rm_rf(command_result.stdout)
      end
    end
  end

  tmp_environment = mk_tmp_environment_with_teardown(master, 'special')
  agents.each do |agent|
    on(agent, puppet("agent -t --environment #{tmp_environment}")) do |result|
      assert_match(/Info: Using environment 'special_\w+'/, result.stdout)
    end

    on(agent, puppet('agent -t')) do |result|
      assert_match(/Info: Using environment 'production'/, result.stdout)
    end
  end
end
