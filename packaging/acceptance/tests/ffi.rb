test_name 'FFI can be required' do

  tag 'audit:low',
      'audit:acceptance'

  require 'puppet/acceptance/common_utils'

  agents.each do |agent|
    step "test require 'ffi'"
      on agent, "#{ruby_command(agent)} -e 'require \"ffi\"'"
  end
end
