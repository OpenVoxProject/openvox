platform 'macos-all-x86_64' do |plat|
  plat.inherit_from_default
  plat.brew '/opt/homebrew/bin/brew'
  plat.cross_compiled true
  plat.output_dir File.join('macos', 'all', 'x86_64')
end
