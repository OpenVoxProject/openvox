def vendor_modules_path(host)
  case host['platform']
  when /windows/
    "'C:\\Program Files\\Puppet Labs\\Puppet\\puppet\\vendor_modules;C:\\Program Files (x86)\\Puppet Labs\\Puppet\\puppet\\vendor_modules'"
  else
    '/opt/puppetlabs/puppet/vendor_modules/'
  end
end

test_name "PA-1998: Validate that vendored modules are installed" do
  step "'module list' lists the vendored modules and reports no missing dependencies" do
    agents.each do |agent|
      vendor_modules = vendor_modules_path(agent)
      on(agent, puppet("module --modulepath=#{vendor_modules} list")) do |result|
        refute_empty(result.stdout.strip, "Expected to find vendor modules in #{vendor_modules}, but the directory did not exist")
        refute_match(/no modules installed/i, result.stdout, "Expected to find vendor modules in #{vendor_modules}, but the directory was empty")
        refute_match(/Missing dependency/i, result.stderr, "Some vendored module dependencies are missing in #{vendor_modules}")
      end
    end
  end

  step "`describe --list` lists vendored module types" do
    vendored_types = %w[
      augeas
      cron
      host
      mount
      scheduled_task
      selboolean
      selmodule
      ssh_authorized_key
      sshkey
      yumrepo
      zfs
      zone
      zpool
    ]
    agents.each do |agent|
      on(agent, puppet("describe --modulepath=#{vendor_modules_path(agent)} --list")) do |result|
        vendored_types.each do |type|
          assert_match(/#{type}/, result.stdout, "Vendored module type `#{type}` didn't appear in the list of known types")
        end
      end
    end
  end
end
