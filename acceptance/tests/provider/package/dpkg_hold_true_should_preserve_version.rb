test_name "dpkg ensure hold package should preserve version if package is already installed" do
  confine :to, :platform => /debian|ubuntu/
  tag 'audit:high',
      'shard:group1' # For splitting out groups of tests for slow test runners

  require 'puppet/acceptance/common_utils'
  extend Puppet::Acceptance::PackageUtils
  extend Puppet::Acceptance::ManifestUtils

  package = "openssl"

  agents.each do |agent|
    teardown do
      on(agent, "apt-mark unhold #{package}")
    end

    step "Ensure hold should lock to specific installed version" do
      existing_installed_version = on(agent, "dpkg -s #{package} | sed -n -e 's/Version: //p'").stdout.strip

      package_manifest_hold = resource_manifest('package', package, mark: "hold")
      apply_manifest_on(agent, package_manifest_hold, :catch_failures => true) do
        installed_version = on(agent, "apt-cache policy #{package} | sed -n -e 's/Installed: //p'").stdout.strip
        assert_equal(existing_installed_version, installed_version)
        assert_match(/\shold$/, on(agent, "dpkg --get-selections #{package}").stdout, "#{package} is not on hold")
      end
    end
  end
end
