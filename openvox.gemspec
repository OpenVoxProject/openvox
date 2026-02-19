# When installed, this gemspec ends up the specifications dir and we should look for
# the library at the installed path because Puppet ends up loading it when invoked.
# When we are building the gem from source, we instead look relative to where this gemspec
# file lives. This is a little jank, but prevents us from having to update the version in
# two different places.
installed_path = "#{__dir__}/../../../vendor_ruby/puppet/version"
version_path = File.exist?("#{installed_path}.rb") ? installed_path : 'lib/puppet/version'
require_relative "#{version_path}"

Gem::Specification.new do |spec|
  spec.name = "openvox"
  spec.version = Puppet.version
  spec.licenses = ['Apache-2.0']

  spec.required_rubygems_version = Gem::Requirement.new("> 1.3.1")
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.0")
  spec.authors = ["OpenVox Project"]
  spec.date = "2012-08-17"
  spec.description = <<~EOF
    OpenVox is a community implementation of Puppet, an automated administrative engine for your Linux, Unix, and Windows systems, performs administrative tasks
    (such as adding users, installing packages, and updating server configurations) based on a centralized specification.
  EOF
  spec.email = "openvox@voxpupuli.org"
  spec.executables = ["puppet"]
  spec.files = Dir['[A-Z]*'] + Dir['install.rb'] + Dir['bin/*'] + Dir['lib/**/*'] + Dir['conf/*'] + Dir['man/**/*'] + Dir['tasks/*'] + Dir['locales/**/*'] + Dir['ext/**/*'] + Dir['examples/**/*']
  spec.license = "Apache-2.0"
  spec.homepage = "https://github.com/OpenVoxProject/openvox"
  spec.rdoc_options = ["--title", "OpenVox - Configuration Management", "--main", "README", "--line-numbers"]
  spec.require_paths = ["lib"]
  spec.summary = "OpenVox, a community implementation of Puppet -- an automated configuration management tool"
  spec.specification_version = 4
  spec.add_runtime_dependency('base64', '>= 0.1', '< 0.4')
  spec.add_runtime_dependency('benchmark', '>= 0.2', '< 0.6')
  spec.add_runtime_dependency('concurrent-ruby', '~> 1.0')
  spec.add_runtime_dependency('deep_merge', '~> 1.0')
  spec.add_runtime_dependency('fast_gettext', '>= 2.1', '< 5')
  spec.add_runtime_dependency('fiddle', '~> 1.1')
  spec.add_runtime_dependency('getoptlong', '~> 0.2.0')
  spec.add_runtime_dependency('locale', '~> 2.1')
  spec.add_runtime_dependency('openfact', '~> 5.0')
  spec.add_runtime_dependency('ostruct', '>= 0.5.5', '< 0.7')
  spec.add_runtime_dependency('puppet-resource_api', '~> 2.0')
  spec.add_runtime_dependency('racc', '~> 1.5')
  spec.add_runtime_dependency('scanf', '~> 1.0')
  spec.add_runtime_dependency('semantic_puppet', '~> 1.0')
  spec.add_runtime_dependency('win32ole', '>= 1.8', '< 2.0') if Gem.win_platform?

  platform = spec.platform.to_s
  if platform == 'universal-darwin'
    spec.add_runtime_dependency('CFPropertyList', ['>= 3.0.6', '< 5'])
  end

  if platform == 'x64-mingw32' || platform == 'x86-mingw32'
    # ffi 1.16.0 - 1.16.2 are broken on Windows
    spec.add_runtime_dependency('ffi', '>= 1.15.5', '< 2', '!= 1.16.0', '!= 1.16.1', '!= 1.16.2')
    spec.add_runtime_dependency('minitar', '~> 1.0')
  end
end
