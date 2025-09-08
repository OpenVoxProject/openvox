platform 'macos-all-arm64' do |plat|
  plat.inherit_from_default
  packages = %w[cmake pkg-config yaml-cpp]
  # We uninstall in case they are already installed, since GitHub Actions runners
  # will already have their own version and we want the homebrew core version.
  # We do || true so it doesn't fail if the packages don't exist. We have to do
  # it one by one because brew will not process the rest if one doesn't exist.
  packages.each do |pkg|
    plat.provision_with "brew uninstall #{pkg} 2>/dev/null || true && brew install #{pkg}"
  end
  plat.output_dir File.join('macos', 'all', 'arm64')
end
