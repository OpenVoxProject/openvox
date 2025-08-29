component 'puppet-runtime' do |pkg, settings, platform|
  unless settings[:puppet_runtime_version] && settings[:puppet_runtime_location] && settings[:puppet_runtime_basename]
    raise "Expected to find :puppet_runtime_version, :puppet_runtime_location, and :puppet_runtime_basename settings; Please set these in your project file before including puppet-runtime as a component."
  end

  pkg.version settings[:puppet_runtime_version]

  tarball_name = "#{settings[:puppet_runtime_basename]}.tar.gz"
  pkg.url File.join(settings[:puppet_runtime_location], tarball_name)
  pkg.sha1sum File.join(settings[:puppet_runtime_location], "#{tarball_name}.sha1")

  pkg.requires 'findutils' if platform.is_linux?

  pkg.install_only true

  # Even though puppet's ruby comes from puppet-runtime, we still need a ruby
  # to build with on these platforms:
  if platform.is_cross_compiled?
    if platform.is_solaris?
      raise "Unknown solaris os_version: #{platform.os_version}" unless platform.os_version == '11'
      pkg.build_requires 'pl-ruby'
    elsif platform.is_linux?
      pkg.build_requires 'pl-ruby'
    elsif platform.is_macos?
      ruby_version_y = settings[:ruby_version].gsub(/(\d+)\.(\d+)\.(\d+)/, '\1.\2')
      pkg.build_requires "ruby@#{ruby_version_y}"
    end
  end

  if platform.is_windows?
    # Elevate.exe is simply used when one of the run_facter.bat or
    # run_puppet.bat files are called. These set up the required environment
    # for the program, and elevate.exe gives the program the elevated
    # privileges it needs to run.
    # Comes from https://github.com/jpassing/elevate
    pkg.add_source "file://resources/files/windows/elevate.exe.config", sum: "a5aecf3f7335fa1250a0f691d754d561"
    pkg.add_source "https://artifacts.overlookinfratech.com/components/elevate.exe", sum: "bd81807a5c13da32dd2a7157f66fa55d"
    pkg.install_file 'elevate.exe.config', "#{settings[:bindir]}/elevate.exe.config"
    pkg.install_file 'elevate.exe', "#{settings[:bindir]}/elevate.exe"

    # We need to make sure we're setting permissions correctly for the executables
    # in the ruby bindir since preserving permissions in archives in windows is
    # ... weird, and we need to be able to use cygwin environment variable use
    # so cmd.exe was not working as expected.
    install_command = [
      "gunzip -c #{tarball_name} | tar -k -C /cygdrive/c/ -xf -",
      "chmod 755 #{settings[:bindir].sub('C:', '/cygdrive/c')}/*"
    ]
  elsif platform.is_macos?
    # We can't untar into '/' because of SIP on macOS; Just copy the contents
    # of these directories instead:
    install_command = [
      "tar -xzf #{tarball_name}",
      "for d in opt var private; do sudo rsync -ka \"$${d}/\" \"/$${d}/\"; done"
    ]
  else
    install_command = ["gunzip -c #{tarball_name} | #{platform.tar} -k -C / -xf -"]
  end

  pkg.install do
    install_command
  end
end
