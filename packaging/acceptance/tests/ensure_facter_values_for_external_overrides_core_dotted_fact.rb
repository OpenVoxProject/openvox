test_name 'Ensure Facter values usage for external fact overriding core dotted fact' do
    agents.each do |agent|

      output = on agent, puppet('config print modulepath')

      if agent.platform =~ /windows/
        delimiter = ';'
      else
        delimiter = ':'
      end
      module_path = output.stdout.split(delimiter)[0]

      foo_module_dir = File.join(module_path, 'foo')
      foo_external_facts_dir = File.join(foo_module_dir, 'facts.d')

      step 'create module directories' do
        agent.mkdir_p(foo_external_facts_dir)
      end

      teardown do
        agent.rm_rf(foo_module_dir)
      end

      step 'create external and custom fact' do
        create_remote_file(agent, File.join(foo_external_facts_dir, "my_fizz_fact.txt"),'ruby.version=1.1.1')
      end

      step 'check that external fact is visible to puppet in $facts' do
        on agent, puppet("apply -e 'notice(\$facts[\"ruby.version\"])'") do |output|
          assert_match(/Notice: .*: 1.1.1/, output.stdout)
        end
      end

      step 'check that external fact is visible to puppet in $facts.dig' do
        on agent, puppet("apply -e 'notice(\$facts.dig(\"ruby.version\"))'") do |output|
          assert_match(/Notice: .*: 1.1.1/, output.stdout)
        end
      end

      step 'check that external fact is visible to puppet in $facts.get' do
        on agent, puppet("apply -e 'notice(\$facts.get(\"\\\"ruby.version\\\"\"))'") do |output|
          assert_match(/Notice: .*: 1.1.1/, output.stdout)
        end
      end

      step 'check that external fact is visible to puppet in getvar' do
        on agent, puppet("apply -e 'notice(getvar(\"facts.\\\"ruby.version\\\"\"))'") do |output|
          assert_match(/Notice: .*: 1.1.1/, output.stdout)
        end
      end
    end
end
