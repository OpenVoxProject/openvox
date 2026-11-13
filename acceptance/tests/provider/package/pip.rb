test_name "pip provider should install, use install_options with latest, and uninstall" do
  confine :to, :platform => /el-|centos/
  tag 'audit:high',
      'shard:group3' # For splitting out groups of tests for slow test runners

  require 'puppet/acceptance/common_utils'
  extend Puppet::Acceptance::PackageUtils
  extend Puppet::Acceptance::ManifestUtils

  package = 'colorize'
  pip_command = 'pip3'
  provider = 'pip3'

  # Returns nil when the package is not installed
  def installed_pip_version(agent, pip_command, package)
    show = on(agent, "#{pip_command} show #{package} --disable-pip-version-check", :acceptable_exit_codes => [0, 1])
    show.stdout[/^Version: (\S+)/, 1]
  end

  agents.each do |agent|
    teardown do
      on(agent, "#{pip_command} uninstall #{package} --disable-pip-version-check --yes", :accept_all_exit_codes => true)
    end

    step "Setup: Install Python and Pip" do
      package_present(agent, 'python3-pip')
    end

    step "Ensure presence of a pip package" do
      package_manifest = resource_manifest('package', package, { ensure: 'present', provider: provider } )
      apply_manifest_on(agent, package_manifest, :catch_failures => true) do
        refute_nil(installed_pip_version(agent, pip_command, package), "#{package} is not installed")
      end
      on(agent, "#{pip_command} uninstall #{package} --disable-pip-version-check --yes")
    end

    step "Install a pip package using version range" do
      package_manifest1 = resource_manifest('package', package, { ensure: '<=1.1.0', provider: provider } )
      package_manifest2 = resource_manifest('package', package, { ensure: '<1.0.4',  provider: provider } )

      # Make a fresh package install (with version lower than or equal to 1.1.0)
      apply_manifest_on(agent, package_manifest1, :expect_changes => true) do
        assert_equal('1.1.0', installed_pip_version(agent, pip_command, package))
      end

      # Reapply same manifest and expect no changes
      apply_manifest_on(agent, package_manifest1, :catch_changes => true)

      # Reinstall over existing package (with version lower than 1.0.4) and expect changes (to be 1.0.3)
      apply_manifest_on(agent, package_manifest2, :expect_changes => true) do
        assert_equal('1.0.3', installed_pip_version(agent, pip_command, package))
      end

      on(agent, "#{pip_command} uninstall #{package} --disable-pip-version-check --yes")
    end

    step "Ensure latest with pip uses install_options" do
      on(agent, "#{pip_command} install #{package} --disable-pip-version-check")
      package_manifest = resource_manifest('package', package, { ensure: 'latest', provider: provider, install_options: { '--index' => 'https://pypi.python.org/simple' } } )
      result = apply_manifest_on(agent, package_manifest, { :catch_failures => true, :debug => true } )
      assert_match(/--index=https:\/\/pypi.python.org\/simple/, result.stdout)
      on(agent, "#{pip_command} uninstall #{package} --disable-pip-version-check --yes")
    end

    step "Uninstall a pip package" do
      on(agent, "#{pip_command} install #{package} --disable-pip-version-check")
      package_manifest = resource_manifest('package', package, { ensure: 'absent', provider: provider } )
      apply_manifest_on(agent, package_manifest, :catch_failures => true) do
        assert_nil(installed_pip_version(agent, pip_command, package))
      end
    end
  end
end
