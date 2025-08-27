test_name 'Ensure facter command can be executed' do

  require 'puppet/acceptance/common_utils'

  agents.each do |agent|
    step "test facter command" do
      facter =  agent['platform'] =~ /win/ ? 'cmd /c facter' : 'facter'
      on agent, "#{facter} --version", :acceptable_exit_codes => [0]
    end
  end
end
