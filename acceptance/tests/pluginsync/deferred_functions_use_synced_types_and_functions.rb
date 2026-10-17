test_name "Deferred functions can use pluginsynced type aliases and Puppet language functions" do
  tag 'audit:high',
      'audit:integration',
      'server',
      'shard:group1' # For splitting out groups of tests for slow test runners

  #
  # Deferred functions are resolved on the agent, so everything they need
  # has to be pluginsynced. This exercises the whole stack: the server's
  # pluginmodules mount, the agent's pluginsync of it into
  # pluginmoduledest, and the agent's loaders resolving a deferred Ruby
  # function whose signature uses a module's type alias, and a deferred
  # Puppet language function that calls it.
  #

  testdir = create_tmpdir_for_user(master, 'deferred_synced_types')
  modules = "#{testdir}/environments/production/modules"
  mod = "#{modules}/deferredtypes"

  step "Create a module with a type alias, a ruby function and a Puppet language function" do
    on(master, "mkdir -p '#{mod}/types' '#{mod}/functions' '#{mod}/lib/puppet/functions/deferredtypes' " \
               "'#{testdir}/environments/production/manifests' '#{testdir}/environments/invalid/manifests'")

    create_remote_file(master, "#{mod}/types/port.pp", <<~'PUPPET')
      type Deferredtypes::Port = Integer[1, 65535]
    PUPPET

    create_remote_file(master, "#{mod}/lib/puppet/functions/deferredtypes/port_to_s.rb", <<~'RUBY')
      Puppet::Functions.create_function(:'deferredtypes::port_to_s') do
        dispatch :port_to_s do
          param 'Deferredtypes::Port', :port
        end

        def port_to_s(port)
          "port #{port}"
        end
      end
    RUBY

    create_remote_file(master, "#{mod}/functions/describe.pp", <<~'PUPPET')
      function deferredtypes::describe(Deferredtypes::Port $port) >> String {
        "described ${deferredtypes::port_to_s($port)}"
      }
    PUPPET

    create_remote_file(master, "#{testdir}/environments/production/manifests/site.pp", <<~'PUPPET')
      notify { 'ruby':
        message => Deferred('deferredtypes::port_to_s', [8140]),
      }
      notify { 'puppet':
        message => Deferred('deferredtypes::describe', [443]),
      }
    PUPPET

    # The same module, called with a value that doesn't match the type alias
    create_remote_file(master, "#{testdir}/environments/invalid/environment.conf", <<~CONF)
      modulepath = #{modules}
    CONF
    create_remote_file(master, "#{testdir}/environments/invalid/manifests/site.pp", <<~'PUPPET')
      notify { 'invalid':
        message => Deferred('deferredtypes::port_to_s', [0]),
      }
    PUPPET

    on(master, "chown -R #{master.puppet['user']}:#{master.puppet['group']} '#{testdir}'")
    on(master, "chmod -R u+rwX,g+rX,o-rwx '#{testdir}'")
  end

  master_opts = {
    'main' => {
      'environmentpath' => "#{testdir}/environments",
    },
  }

  pluginmoduledests = {}
  agents.each do |agent|
    pluginmoduledests[agent] = agent.tmpdir('plugin_modules')
    teardown do
      on(agent, puppet('config print lastrunfile')) do |result|
        agent.rm_rf(result.stdout.chomp)
      end
      agent.rm_rf("#{agent.puppet['vardir']}/lib/puppet/functions/deferredtypes")
      agent.rm_rf(pluginmoduledests[agent])
    end
  end

  with_puppet_running_on(master, master_opts, testdir) do
    agents.each do |agent|
      pluginmoduledest = pluginmoduledests[agent]

      step "Pluginsync the type alias and function and resolve the deferred functions on #{agent}" do
        on(agent, puppet('agent', '-t', '--environment', 'production', '--pluginmoduledest', pluginmoduledest),
           :acceptable_exit_codes => [2]) do |result|
          assert_match(/port 8140/, result.stdout, "The deferred ruby function using a synced type alias was not resolved")
          assert_match(/described port 443/, result.stdout, "The deferred Puppet language function was not resolved")
        end
      end

      step "Ensure the type alias and function were synced into per-module directories on #{agent}" do
        on(agent, "test -f '#{pluginmoduledest}/deferredtypes/types/port.pp'")
        on(agent, "test -f '#{pluginmoduledest}/deferredtypes/functions/describe.pp'")
        on(agent, "test ! -e '#{pluginmoduledest}/deferredtypes/lib'")
      end

      step "Ensure the synced type alias is enforced on #{agent}" do
        on(agent, puppet('agent', '-t', '--environment', 'invalid', '--pluginmoduledest', pluginmoduledest),
           :acceptable_exit_codes => [1]) do |result|
          assert_match(/expects a Deferredtypes::Port = Integer\[1, 65535\] value, got Integer\[0, 0\]/, result.stderr,
                       "The deferred function was not rejected by the synced type alias")
        end
      end
    end
  end

  master_opts['server'] = { 'serve_pluginmodules' => false }
  with_puppet_running_on(master, master_opts, testdir) do
    agents.each do |agent|
      pluginmoduledest = pluginmoduledests[agent]

      step "Ensure previously synced type aliases and functions are removed when the server stops serving them on #{agent}" do
        on(agent, puppet('agent', '-t', '--environment', 'production', '--pluginmoduledest', pluginmoduledest),
           :acceptable_exit_codes => [1]) do |result|
          assert_match(/references an unresolved type 'Deferredtypes::Port'/, result.stderr,
                       "The deferred function should not find the type alias when the server does not serve it")
        end
        on(agent, "test ! -e '#{pluginmoduledest}/deferredtypes'")
      end
    end
  end
end
