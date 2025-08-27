test_name 'Ensure Facter values usage for dotted custom fact' do
    agents.each do |agent|

      output = on agent, puppet('config print modulepath')

      if agent.platform =~ /windows/
        delimiter = ';'
      else
        delimiter = ':'
      end
      module_path = output.stdout.split(delimiter)[0]

      foo_module_dir = File.join(module_path, 'foo')
      foo_facts_dir = File.join(foo_module_dir, 'lib', 'facter')

      step 'create module directories' do
        agent.mkdir_p(foo_facts_dir)
      end

      teardown do
        agent.rm_rf(foo_module_dir)
      end

      step 'create simple custom fact' do
        create_remote_file(agent, File.join(foo_facts_dir, "my_fizz_fact.rb"), <<-FILE)
Facter.add('f.i.z.z') do
  setcode do
    'buzz'
  end
end
FILE
      end

      step 'check that custom fact is visible to puppet in $facts' do
        on agent, puppet("apply -e 'notice(\$facts[\"f.i.z.z\"])'") do |output|
          assert_match(/Notice: .*: buzz/, output.stdout)
        end
      end

      step 'check that custom fact is visible to puppet in $facts.dig' do
        on agent, puppet("apply -e 'notice(\$facts.dig(\"f.i.z.z\"))'") do |output|
          assert_match(/Notice: .*: buzz/, output.stdout)
        end
      end

      step 'check that custom fact is visible to puppet in $facts.get' do
        on agent, puppet("apply -e 'notice(\$facts.get(\"\\\"f.i.z.z\\\"\"))'") do |output|
          assert_match(/Notice: .*: buzz/, output.stdout)
        end
      end

      step 'check that custom fact is visible to puppet in getvar' do
        on agent, puppet("apply -e 'notice(getvar(\"facts.\\\"f.i.z.z\\\"\"))'") do |output|
          assert_match(/Notice: .*: buzz/, output.stdout)
        end
      end
    end
end
