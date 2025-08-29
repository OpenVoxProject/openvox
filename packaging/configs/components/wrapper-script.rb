# This component creates wrapper scripts to clean up the environment on UNIX platforms
component "wrapper-script" do |pkg, settings, platform|

  pkg.add_source "file://resources/files/aix-wrapper.sh"
  pkg.add_source "file://resources/files/osx-wrapper.sh"
  pkg.add_source "file://resources/files/sysv-wrapper.sh"

  wrapper = "#{settings[:bindir]}/wrapper.sh"

  if platform.is_aix?
    pkg.install_file "aix-wrapper.sh", wrapper, mode: '0755'
  elsif platform.is_macos?
    pkg.install_file "osx-wrapper.sh", wrapper, mode: '0755'
  else
    pkg.install_file "sysv-wrapper.sh", wrapper, mode: '0755'
  end

  ["facter", "puppet"].each do |exe|
    pkg.link wrapper, "#{settings[:link_bindir]}/#{exe}"
  end
end
