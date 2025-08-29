component "openfact" do |pkg, settings, platform|
  pkg.load_from_json('configs/components/openfact.json')

  pkg.build_requires 'puppet-runtime' # Provides ruby and rubygem-deep-merge

  flags = " --bindir=#{settings[:bindir]} \
            --sitelibdir=#{settings[:ruby_vendordir]} \
            --man \
            --mandir=#{settings[:mandir]} \
            --ruby=#{File.join(settings[:bindir], 'ruby')} "

  if platform.is_windows?
    pkg.add_source("file://resources/files/windows/facter.bat", sum: "eabed128c7160289790a2b59a84a9a13")
    pkg.add_source("file://resources/files/windows/facter_interactive.bat", sum: "20a1c0bc5368ffb24980f42432f1b372")
    pkg.add_source("file://resources/files/windows/run_facter_interactive.bat", sum: "c5e0c0a80e5c400a680a06a4bac8abd4")

    pkg.install_file "../facter.bat", "#{settings[:link_bindir]}/facter.bat"
    pkg.install_file "../facter_interactive.bat", "#{settings[:link_bindir]}/facter_interactive.bat"
    pkg.install_file "../run_facter_interactive.bat", "#{settings[:link_bindir]}/run_facter_interactive.bat"
  end

  pkg.install do
    [
      "#{settings[:host_ruby]} install.rb \
      --no-batch-files \
      --no-configs \
      #{flags}"
    ]
  end

  pkg.install_file "openfact.gemspec", "#{settings[:gem_home]}/specifications/#{pkg.get_name}-#{pkg.get_version_forced}.gemspec"

  if platform.is_windows?
    pkg.directory File.join(settings[:sysconfdir], 'facter', 'facts.d')
  else
    pkg.directory File.join(settings[:install_root], 'facter', 'facts.d')
  end
end
