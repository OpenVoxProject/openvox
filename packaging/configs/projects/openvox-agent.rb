project 'openvox-agent' do |proj|
  platform = proj.get_platform

  generate_source_artifacts true

  # puppet-agent inherits most build settings from openvoxproject/puppet-runtime:
  # - Modifications to global settings like flags and target directories should be made in puppet-runtime.
  # - Settings included in this file should apply only to local components in this repository.
  runtime_details = JSON.parse(File.read('configs/components/puppet-runtime.json'))
  agent_branch = 'main'

  settings[:puppet_runtime_version] = runtime_details['version']
  settings[:puppet_runtime_location] = runtime_details['location']
  settings[:puppet_runtime_basename] = "agent-runtime-#{agent_branch}-#{runtime_details['version']}.#{platform.name}"

  settings_uri = File.join(runtime_details['location'], "#{proj.settings[:puppet_runtime_basename]}.settings.yaml")
  sha1sum_uri = "#{settings_uri}.sha1"
  metadata_uri = File.join(runtime_details['location'], "#{proj.settings[:puppet_runtime_basename]}.json")
  proj.inherit_yaml_settings(settings_uri, sha1sum_uri, metadata_uri: metadata_uri)

  if platform.is_fedora? || platform.name =~ /el-10/
    proj.package_override("# Disable check-rpaths since /opt/* is not a valid path\n%global __brp_check_rpaths %{nil}")
    proj.package_override("# Disable the removal of la files, they are still required\n%global __brp_remove_la_files %{nil}")
  end

  # Override gem related commands since runtime was natively compiled, but we're
  # cross compiling this project.
  if platform.name == 'solaris-11-sparc'
    proj.setting(:host_ruby, '/opt/pl-build-tools/bin/ruby')
    proj.setting(:host_gem, '/opt/pl-build-tools/bin/gem')
    proj.setting(:gem_install, '/opt/pl-build-tools/bin/gem install --no-rdoc --no-ri --local ')
  end

  # Project level settings our components will care about
  if platform.is_windows?
    proj.setting(:company_name, "Vox Pupuli")
    proj.setting(:pl_company_name, "Puppet Labs")
    proj.setting(:common_product_id, "PuppetInstaller")
    proj.setting(:puppet_service_name, "puppet")
    proj.setting(:upgrade_code, "2AD3D11C-61B3-4710-B106-B4FDEC5FA358")
    if platform.architecture == "x64"
      proj.setting(:product_name, "OpenVox Agent (64-bit)")
      proj.setting(:win64, "yes")
      proj.setting(:RememberedInstallDirRegKey, "RememberedInstallDir64")
    else
      proj.setting(:product_name, "OpenVox Agent")
      proj.setting(:win64, "no")
      proj.setting(:RememberedInstallDirRegKey, "RememberedInstallDir")
    end
    proj.setting(:links, {
        :HelpLink => "https://github.com/OpenVoxProject",
        :CommunityLink => "https://voxpupuli.org",
        :ForgeLink => "http://forge.puppet.com",
        :NextStepLink => "https://docs.puppet.com/pe/latest/quick_start_install_agents_windows.html",
        :ManualLink => "https://docs.puppet.com/puppet/latest/reference",
      })
    proj.setting(:UI_exitdialogtext, "Manage your first resources on this node, explore the Puppet community and get support using the shortcuts in the Documentation folder of your Start Menu.")
    proj.setting(:LicenseRTF, "wix/license/LICENSE.rtf")

    # Directory IDs
    proj.setting(:bindir_id, "bindir")

    proj.setting(:service_dir, File.join(proj.install_root, "service"))
  end

  proj.setting(:puppet_configdir, File.join(proj.sysconfdir, 'puppet'))
  proj.setting(:puppet_codedir, File.join(proj.sysconfdir, 'code'))

  # Target directory for vendor modules
  proj.setting(:module_vendordir, File.join(proj.prefix, 'vendor_modules'))

  # Used to construct download URLs for forge modules in _base-module.rb
  proj.setting(:forge_download_baseurl, "https://forge.puppet.com/v3/files")

  proj.setting(:service_conf, File.join(proj.install_root, 'service_conf'))

  proj.description "The OpenVox Agent package contains all of the elements needed to run the agent, including ruby and openfact."
  if ENV['OPENVOX_AGENT_VERSION']
    proj.version ENV['OPENVOX_AGENT_VERSION']
  else
    proj.version_from_git
  end
  proj.write_version_file File.join(proj.prefix, 'VERSION')
  proj.license "See components"
  proj.vendor "Vox Pupuli <openvox@voxpupuli.org>"
  proj.homepage "https://voxpupuli.org"

  major = proj.get_version.split('.').first
  proj.target_repo "openvox#{major}"

  if platform.is_solaris?
    proj.identifier "voxpupuli.org"
  elsif platform.is_macos?
    proj.identifier "org.voxpupuli"
  end

  # For some platforms the default doc location for the BOM does not exist or is incorrect - move it to specified directory
  if platform.name =~ /cisco-wrlinux/
    proj.bill_of_materials File.join(proj.datadir, "doc")
  end

  # Set package version, for use by Facter in creating the AIO_AGENT_VERSION fact.
  proj.setting(:package_version, proj.get_version)

  # Provides augeas, curl, libedit, libxml2, libxslt, openssl, puppet-ca-bundle, ruby and rubygem-*
  proj.component "puppet-runtime"
  proj.component 'openssl-fips' if platform.is_fips?

  proj.component "puppet"
  proj.component "openfact"

  proj.component "puppet-resource_api"

  # These utilites don't really work on unix
  if platform.is_linux?
    proj.component "shellpath"
  end

  # Windows doesn't need these wrappers, only unix platforms
  unless platform.is_windows?
    proj.component "wrapper-script"
  end

  # Execution wrapper used by Choria
  proj.component "execution_wrapper"

  # Vendored modules
  proj.component "module-puppetlabs-augeas_core"
  proj.component "module-puppetlabs-cron_core"
  proj.component "module-puppetlabs-host_core"
  proj.component "module-puppetlabs-mount_core"
  proj.component "module-puppetlabs-scheduled_task"
  proj.component "module-puppetlabs-selinux_core"
  proj.component "module-puppetlabs-sshkeys_core"
  proj.component "module-puppetlabs-yumrepo_core"
  proj.component "module-puppetlabs-zfs_core"
  proj.component "module-puppetlabs-zone_core"

  # Including headers can make the package unacceptably large; This component
  # removes files that aren't required.
  # Set the $DEV_BUILD environment variable to leave headers in place.
  proj.component "cleanup"

  proj.component 'pl-ruby-patch' if platform.is_cross_compiled?

  unless ENV['DEV_BUILD'].to_s.empty?
    proj.settings[:dev_build] = true
  end

  proj.directory proj.install_root
  proj.directory proj.prefix
  proj.directory proj.sysconfdir
  proj.directory proj.link_bindir
  proj.directory proj.logdir unless platform.is_windows?
  proj.directory proj.piddir unless platform.is_windows? || platform.is_solaris?
  if platform.is_windows? || platform.is_macos?
    proj.directory proj.bindir
  end

  # make sure we can replace puppet-agent in place for the rename
  proj.replaces 'puppet-agent', "< #{major.to_i + 1}"
  proj.conflicts 'puppet-agent'
  if platform.is_rpm?
    proj.provides 'puppet-agent', "= #{major}"
  elsif platform.is_deb?
    proj.provides 'puppet-agent', "(= #{major})"
  end

  proj.timeout 7200 if platform.is_windows?
end
