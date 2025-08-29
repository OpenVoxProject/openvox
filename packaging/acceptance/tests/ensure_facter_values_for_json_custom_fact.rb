test_name 'Ensure Facter values usage for json custom fact' do
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

      step 'create simple external fact' do
        create_remote_file(agent, File.join(foo_facts_dir, "my_fizz_fact.rb"), <<-FILE)
Facter.add(:fizz) do
  setcode do
    '{"bizz": "buzz"}'
  end
end
FILE
      end

      step 'check that json custom fact is visible to puppet in $facts' do
        on agent, puppet("apply -e 'notice(\$facts[\"fizz\"])'") do |output|
          assert_match(/Notice: .*: {"bizz": "buzz"}/, output.stdout)
        end
      end

      step 'check that json custom fact is visible to puppet in $facts.dig' do
        on agent, puppet("apply -e 'notice(\$facts.dig(\"fizz\"))'") do |output|
          assert_match(/Notice: .*: {"bizz": "buzz"}/, output.stdout)
        end
      end

      step 'check that json custom fact is visible to puppet in $facts.get' do
        on agent, puppet("apply -e 'notice(\$facts.get(\"fizz\"))'") do |output|
          assert_match(/Notice: .*: {"bizz": "buzz"}/, output.stdout)
        end
      end

      step 'check that json custom fact is visible to puppet in getvar' do
        on agent, puppet("apply -e 'notice(getvar(\"facts.fizz\"))'") do |output|
          assert_match(/Notice: .*: {"bizz": "buzz"}/, output.stdout)
        end
      end

      step 'check that json custom fact key is not visible to puppet in $facts' do
        on agent, puppet("apply -e 'notice(\$facts[\"fizz.buzz\"])'") do |output|
          refute_match(/Notice: .*: {"bizz": "buzz"}/, output.stdout)
        end
      end

      step 'check that json custom fact key is not visible to puppet in $facts.dig' do
        on agent, puppet("apply -e 'notice(\$facts.dig(\"fizz.buzz\"))'") do |output|
          refute_match(/Notice: .*: {"bizz": "buzz"}/, output.stdout)
        end
      end

      step 'check that json custom fact key is not visible to puppet in $facts.get' do
        on agent, puppet("apply -e 'notice(\$facts.get(\"fizz.buzz\"))'"), acceptable_exit_codes: [1] do |output|
          refute_match(/Notice: .*: {"bizz": "buzz"}/, output.stdout)
        end
      end

      step 'check that json custom fact key is not visible to puppet in getvar' do
        on agent, puppet("apply -e 'notice(getvar(\"facts.fizz.buzz\"))'"), acceptable_exit_codes: [1] do |output|
          refute_match(/Notice: .*: {"bizz": "buzz"}/, output.stdout)
        end
      end
    end
end
