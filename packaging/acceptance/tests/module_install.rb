test_name 'PA-3125: make sure we can install a forge module' do

  tag 'audit:high',
      'audit:acceptance'

  require 'puppet/acceptance/common_utils'
  module_name = "puppetlabs/mailalias_core"
  agents.each do |agent|
    need_to_uninstall = false

    teardown do
      on agent, puppet("module", "uninstall", "--force", module_name) if need_to_uninstall
    end
    
    step "test we can install puppetlabs/mailalias_core forge module" do
      on agent, puppet("module", "install", module_name) do |result|
        need_to_uninstall = true unless result.stdout =~ /Module .* is already installed./
      end
    end
  end
end
