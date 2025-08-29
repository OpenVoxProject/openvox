test_name 'Ensure Facter values usage for external fact overriding custom and core top fact' do
    agents.each do |agent|

      output = on agent, puppet('config print modulepath')

      if agent.platform =~ /windows/
        delimiter = ';'
      else
        delimiter = ':'
      end
      module_path = output.stdout.split(delimiter)[0]

      foo_module_dir = File.join(module_path, 'foo')
      foo_custom_facts_dir = File.join(foo_module_dir, 'lib', 'facter')
      foo_external_facts_dir = File.join(foo_module_dir, 'facts.d')

      custom_ruby_value = '{"version": "1.1.1"}'
      external_ruby_value = '{"version": "0.0.0"}'

      step 'create module directories' do
        agent.mkdir_p(foo_custom_facts_dir)
        agent.mkdir_p(foo_external_facts_dir)
      end

      teardown do
        agent.rm_rf(foo_module_dir)
      end

      step 'create external and custom fact' do
        create_remote_file(agent, File.join(foo_custom_facts_dir, "my_fizz_fact.rb"), <<-FILE)
Facter.add('ruby') do
  has_weight(999)
  setcode do
    '#{custom_ruby_value}'
  end
end
FILE
        create_remote_file(agent, File.join(foo_external_facts_dir, "my_fizz_fact.txt"),"ruby=#{external_ruby_value}")
      end

      step 'check that json custom fact is visible to puppet in $facts' do
        on agent, puppet("apply -e 'notice(\$facts[\"ruby\"])'") do |output|
          assert_match(/Notice: .*: #{external_ruby_value}/, output.stdout)
        end
      end

      step 'check that json custom fact is visible to puppet in $facts.dig' do
        on agent, puppet("apply -e 'notice(\$facts.dig(\"ruby\"))'") do |output|
          assert_match(/Notice: .*: #{external_ruby_value}/, output.stdout)
        end
      end

      step 'check that json custom fact is visible to puppet in $facts.get' do
        on agent, puppet("apply -e 'notice(\$facts.get(\"ruby\"))'") do |output|
          assert_match(/Notice: .*: #{external_ruby_value}/, output.stdout)
        end
      end

      step 'check that json custom fact is visible to puppet in getvar' do
        on agent, puppet("apply -e 'notice(getvar(\"facts.ruby\"))'") do |output|
          assert_match(/Notice: .*: #{external_ruby_value}/, output.stdout)
        end
      end

      step 'check that json custom fact is interpreted as text' do
        on agent, puppet("apply -e 'notice(\$facts[\"ruby\"][\"version\"])'") , acceptable_exit_codes: [1]  do |output|
          refute_match(/Notice: .*: 1.1.1/, output.stdout)
        end
      end
    end
end
