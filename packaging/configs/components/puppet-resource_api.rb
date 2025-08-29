component "puppet-resource_api" do |pkg, settings, platform|
  pkg.load_from_json("configs/components/puppet-resource_api.json")

  pkg.build_requires "puppet-runtime"

  # Install into the directory for gems shared by puppet and puppetserver
  pkg.environment "GEM_HOME", settings[:puppet_gem_vendor_dir]

  # PA-25 in order to install gems in a cross-compiled environment we need to
  # set RUBYLIB to include puppet, so that its gemspec can resolve
  # puppet/version requires. Without this the gem install
  # will fail by blowing out the stack.
  pkg.environment "RUBYLIB", "#{settings[:ruby_vendordir]}:$(RUBYLIB)"

  pkg.build do
    ["#{settings[:host_gem]} build puppet-resource_api.gemspec"]
  end

  pkg.install do
    ["#{settings[:gem_install]} puppet-resource_api-*.gem"]
  end
end
