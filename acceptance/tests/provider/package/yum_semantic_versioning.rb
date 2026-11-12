test_name "yum provider should use semantic versioning for ensuring desired version" do
  confine :to, :platform => /el-|centos|fedora/
  tag 'audit:high',
      'shard:group2' # For splitting out groups of tests for slow test runners

  require 'puppet/acceptance/common_utils'
  require 'puppet/acceptance/rpm_util'
  extend Puppet::Acceptance::ManifestUtils
  extend Puppet::Acceptance::RpmUtils

  package = 'semvertest'
  rpm_options = {:pkg => package}

  # send_rpm builds release 1 of each version. As text, 1.9 sorts after 1.11,
  # so the ranges below only pick the right versions when compared as numbers.
  versions = ['1.9', '1.10', '1.11']
  lower_package_version, middle_package_version, higher_package_version = versions.map { |version| "#{version}-1" }

  agents.each do |agent|
    package_command = rpm_provider(agent)

    teardown do
      clean_rpm(agent, rpm_options)
    end

    step "Setup: Build #{package} #{versions.join(', ')} in a local repository" do
      clean_rpm(agent, rpm_options)
      setup_rpm(agent, rpm_options)
      versions.each do |version|
        send_rpm(agent, rpm_options.merge(:version => version))
      end
    end

    step "Using semantic versioning to downgrade to a desired version <= X" do
      on(agent, "#{package_command} install #{package} -y")
      package_manifest = resource_manifest('package', package, { ensure: "<=#{lower_package_version}" } )
      apply_manifest_on(agent, package_manifest, :catch_failures => true) do
        assert_equal("#{package}-#{lower_package_version}.noarch", on(agent, "rpm -q #{package}").stdout.strip)
      end
      # idempotency test
      apply_manifest_on(agent, package_manifest, :catch_changes => true)
      on(agent, "#{package_command} remove #{package} -y")
    end

    step "Using semantic versioning to ensure a version >X <=Y" do
      on(agent, "#{package_command} install #{package} -y")
      package_manifest = resource_manifest('package', package, { ensure: ">#{lower_package_version} <=#{higher_package_version}" } )
      apply_manifest_on(agent, package_manifest, :catch_failures => true) do
        assert_equal("#{package}-#{higher_package_version}.noarch", on(agent, "rpm -q #{package}").stdout.strip)
      end
      on(agent, "#{package_command} remove #{package} -y")
    end

    step "Using semantic versioning to install a version >X <Y" do
      package_manifest = resource_manifest('package', package, { ensure: ">#{lower_package_version} <#{higher_package_version}" } )
      # installing a version >X <Y will install the highest version in between
      apply_manifest_on(agent, package_manifest, :catch_failures => true) do
        assert_equal("#{package}-#{middle_package_version}.noarch", on(agent, "rpm -q #{package}").stdout.strip)
      end
      on(agent, "#{package_command} remove #{package} -y")
    end
  end
end
