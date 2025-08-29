platform 'osx-13-arm64' do |plat|
  plat.inherit_from_default
  packages = %w[cmake pkg-config yaml-cpp]
  plat.provision_with "su test -c '/opt/homebrew/bin/brew install #{packages.join(' ')}'"
  plat.output_dir File.join('apple', '13', 'puppet8', 'arm64')
end
