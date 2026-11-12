test_name "dpkg ensure hold package is latest installed" do
  confine :to, :platform => /debian|ubuntu/
  tag 'audit:high',
      'shard:group4' # For splitting out groups of tests for slow test runners

  require 'puppet/acceptance/common_utils'
  extend Puppet::Acceptance::PackageUtils
  extend Puppet::Acceptance::ManifestUtils

  package = "nginx"

  agents.each do |agent|
    teardown do
      on(agent, "apt-mark unhold #{package}")
      package_absent(agent, package)
    end

    step "Ensure that package is installed first if not present" do
      expected_package_version = on(agent, "apt-cache policy #{package} | sed -n -e 's/Candidate: //p'").stdout.strip
      package_manifest = resource_manifest('package', package, mark: "hold")

      apply_manifest_on(agent, package_manifest, :catch_failures => true) do
        installed_package_version = on(agent, "apt-cache policy #{package} | sed -n -e 's/Installed: //p'").stdout.strip
        assert_equal(expected_package_version, installed_package_version)
        assert_match(/\shold$/, on(agent, "dpkg --get-selections #{package}").stdout, "#{package} is not on hold")
      end
    end
  end
end
