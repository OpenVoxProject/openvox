test_name 'puppet agent runs without /etc/hosts' do
  tag 'audit:high',
      'audit:acceptance'

  agents.each do |agent|
    skip_test('This test only applies to Linux agents') if agent['platform'] =~ /windows/

    hosts_file = '/etc/hosts'
    backup_dir = agent.tmpdir('missing_hosts_file')
    backup_hosts = File.join(backup_dir, 'hosts')

    teardown do
      on(agent, "if test -f #{backup_hosts}; then cp #{backup_hosts} #{hosts_file}; fi")
    end

    step 'Back up /etc/hosts and remove it' do
      on(agent, "mkdir -p #{backup_dir}")
      on(agent, "if test -f #{hosts_file}; then cp #{hosts_file} #{backup_hosts}; fi")
      on(agent, "rm -f #{hosts_file}")
      on(agent, "test ! -e #{hosts_file}")
    end

    step 'Run puppet agent without /etc/hosts' do
      on(agent, puppet('agent --test'), acceptable_exit_codes: [0, 2]) do |result|
        assert_match(/Applied catalog/, result.stdout)
      end
    end
  end
end
