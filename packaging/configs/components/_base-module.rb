# This file is a basis for vendor modules that should be installed alongside
# puppet-agent in settings[:module_vendordir]. It should not be used as a
# component; Instead, other module components should load it using
# `instance_eval`. Here's an example:
#
# component "module-puppetlabs-stdlib" do |pkg, settings, platform|
#   pkg.version "4.25.1"
#   pkg.md5sum "f18f3361cb8c85770e96eeed05358f05"
#
#   instance_eval File.read("configs/components/_base-module.rb")
# end
#
# Module components must be named with the following format:
#   module-<module-author>-<module-name>.rb
#
# No dependency resolution is attempted automatically; You must define separate
# vanagon components for each module and make their dependencies explicit.

unless defined?(pkg)
  raise "_base-module.rb is not a valid vanagon component; Load it with `instance_eval` in another component instead."
end

match_data = pkg.get_name.match(/module-([^-]+)-([^-]+)/)
unless match_data
  raise "module components must be named with the format `module-<module-author>-<module-name>.rb`"
end
module_author, module_name = match_data.captures

# Modules must have puppet
pkg.build_requires 'puppet'

# This is just a tarball; Skip unpack, patch, configure, build, check steps
pkg.install_only true

# Ensure the vendored modules directory makes it into the package with the right permissions
if platform.is_windows?
  pkg.directory(settings[:module_vendordir])
else
  pkg.directory(settings[:module_vendordir], mode: '0755', owner: 'root', group: 'root')
end

target_directory = File.join(settings[:module_vendordir], module_name)

pkg.install do
  [
    # Rename appropriately for use with puppet
    "mv #{module_author}-#{module_name} #{target_directory}",
    # Remove git and CI-related files
    "rm -r #{File.join(target_directory, '.[!.]*')} 2>/dev/null",
  ]
end
