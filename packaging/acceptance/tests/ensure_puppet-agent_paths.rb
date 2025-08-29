# ensure installs and code honor new puppet-agent path spec:
# https://github.com/puppetlabs/puppet-specifications/blob/master/file_paths.md
test_name 'PUP-4033: Ensure aio path spec is honored'

tag 'audit:high',
    'audit:acceptance',
    'audit:refactor'    # move to puppet-agent acceptance


require 'puppet/acceptance/common_utils'
extend Puppet::Acceptance::CommandUtils

# include file_exists?
require 'puppet/acceptance/temp_file_utils'
extend Puppet::Acceptance::TempFileUtils

def config_options(agent)
  platform = agent[:platform]
  case platform
  when /windows/
    common_app_data = 'C:/ProgramData'
    puppetlabs_data = "#{common_app_data}/PuppetLabs"

    codedir = "#{puppetlabs_data}/code"
    confdir = "#{puppetlabs_data}/puppet/etc"
    vardir = "#{puppetlabs_data}/puppet/cache"
    publicdir = "#{puppetlabs_data}/puppet/public"
    logdir = "#{puppetlabs_data}/puppet/var/log"
    rundir = "#{puppetlabs_data}/puppet/var/run"
    facterdir = "#{puppetlabs_data}/facter"
    sep = ";"

    module_working_dir = on(agent, "#{ruby_command(agent)} -e 'require \"tmpdir\"; print Dir.tmpdir'").stdout.chomp
  else
    codedir = '/etc/puppetlabs/code'
    confdir = '/etc/puppetlabs/puppet'
    vardir = '/opt/puppetlabs/puppet/cache'
    publicdir = '/opt/puppetlabs/puppet/public'
    logdir = '/var/log/puppetlabs/puppet'
    rundir = '/var/run/puppetlabs'
    facterdir = "/opt/puppetlabs/facter"
    sep = ":"

    module_working_dir = "#{vardir}/puppet-module"
  end

  [
    # code
    {:name => :codedir,         :expected => codedir,                     :installed => :dir},
    {:name => :environmentpath, :expected => "#{codedir}/environments"},

    # confdir
    {:name => :confdir,                  :expected => confdir,                     :installed => :dir},
    {:name => :autosign,                 :expected => "#{confdir}/autosign.conf"},
    {:name => :binder_config,            :expected => ""},
    {:name => :csr_attributes,           :expected => "#{confdir}/csr_attributes.yaml"},
    {:name => :trusted_oid_mapping_file, :expected => "#{confdir}/custom_trusted_oid_mapping.yaml"},
    {:name => :deviceconfig,             :expected => "#{confdir}/device.conf"},
    {:name => :fileserverconfig,         :expected => "#{confdir}/fileserver.conf"},
    {:name => :config,                   :expected => "#{confdir}/puppet.conf",    :installed => :file},
    {:name => :route_file,               :expected => "#{confdir}/routes.yaml"},
    {:name => :ssldir,                   :expected => "#{confdir}/ssl",            :installed => :dir},
    {:name => :hiera_config,             :expected => "#{confdir}/hiera.yaml"},

    # vardir
    {:name => :vardir,                   :expected => "#{vardir}",                 :installed => :dir},
    {:name => :bucketdir,                :expected => "#{vardir}/bucket"},
    {:name => :devicedir,                :expected => "#{vardir}/devices"},
    {:name => :pluginfactdest,           :expected => "#{vardir}/facts.d",         :installed => :dir},
    {:name => :libdir,                   :expected => "#{vardir}/lib",             :installed => :dir},
    {:name => :factpath,                 :expected => "#{vardir}/lib/facter#{sep}#{vardir}/facts", :not_path => true},
    {:name => :module_working_dir,       :expected => module_working_dir},
    {:name => :reportdir,                :expected => "#{vardir}/reports"},
    {:name => :server_datadir,           :expected => "#{vardir}/server_data"},
    {:name => :statedir,                 :expected => "#{vardir}/state",           :installed => :dir},
    {:name => :yamldir,                  :expected => "#{vardir}/yaml"},

    # logdir/rundir
    {:name => :logdir,                   :expected => logdir,                      :installed => :dir},
    {:name => :rundir,                   :expected => rundir,                      :installed => :dir},
    {:name => :pidfile,                  :expected => "#{rundir}/agent.pid"},

    # publicdir
    {:name => :publicdir,                :expected => publicdir,                   :installed => :dir},

    #non-Puppet config dirs
    {:name => :facter_factsdir,          :expected => "#{facterdir}/facts.d",      :installed => :dir, :not_puppet_config => true},
  ]
end

step 'test configprint outputs'
agents.each do |agent|
  on(agent, puppet_agent('--configprint all')) do |result|
    config_options(agent).select {|v| !v[:not_puppet_config] }.each do |config_option|
      assert_match("#{config_option[:name]} = #{config_option[:expected]}", result.stdout)
    end
  end
end

step 'test puppet genconfig entries'
agents.each do |agent|
  on(agent, puppet_agent('--genconfig')) do |result|
    config_options(agent).select {|v| !v[:not_puppet_config] }.each do |config_option|
      assert_match("#{config_option[:name]} = #{config_option[:expected]}", result.stdout)
    end
  end
end

step 'test puppet agent paths exist'
agents.each do |agent|
  config_options(agent).select {|v| !v[:not_path] }.each do |config_option|
    path = config_option[:expected]
    case config_option[:installed]
    when :dir
      if !dir_exists?(agent, path)
        fail_test("Failed to find expected directory '#{path}' on agent '#{agent}'")
      end
    when :file
      if !file_exists?(agent, path)
        fail_test("Failed to find expected file '#{path}' on agent '#{agent}'")
      end
    end
  end
end


public_binaries = {
  :posix => ['puppet', 'facter'],
  :win   => ['puppet.bat', 'facter.bat']
}

def locations(platform, ruby_arch, type)
  if type == 'foss'
    return '/usr/bin'
  end

  case platform
  when /windows/
    # If undefined, ruby_arch defaults to x86
    if ruby_arch == 'x64'
      ruby_arch = /-64/
    else
      ruby_arch = /-32/
    end
    if platform =~ ruby_arch
      return 'C:/Program Files/Puppet Labs/Puppet/bin'
    else
      return 'C:/Program Files (x86)/Puppet Labs/Puppet/bin'
    end
  else
    return '/opt/puppetlabs/bin'
  end
end

step 'test puppet binaries exist'
agents.each do |agent|
  dir = locations(agent[:platform], agent[:ruby_arch], @options[:type])
  os = agent['platform'] =~ /windows/ ? :win : :posix

  file_type =  (@options[:type] == 'git' || os == :win) ? :binary : :symlink

  public_binaries[os].each do |binary|
    path = File.join(dir, binary)
    case file_type
    when :binary
      if !file_exists?(agent, path)
        fail_test("Failed to find expected binary '#{path}' on agent '#{agent}'")
      end
    when :symlink
      if !link_exists?(agent, path)
        fail_test("Failed to find expected symbolic link '#{path}' on agent '#{agent}'")
      end
    end
  end
end

