test_name 'PA-3067: Manage selinux' do

  tag 'audit:high',
      'audit:acceptance'

  confine :to, :platform => /el-|fedora-|debian-|ubuntu-/
  confine :except, :platform => /el-6/

  require 'puppet/acceptance/common_utils'

  agents.each do |agent|
    step "test require 'selinux'"
      on agent, "#{ruby_command(agent)} -e 'require \"selinux\"'"
  end
end
