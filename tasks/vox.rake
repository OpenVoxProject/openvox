namespace :vox do
  desc 'Update the version in preparation for a release'
  task 'version:bump:full', [:version] do |_, args|
    abort 'You must provide a tag.' if args[:version].nil? || args[:version].empty?
    version = args[:version]
    abort "#{version} does not appear to be a valid version string in x.y.z format" unless Gem::Version.correct?(version)

    # Update lib/puppet/version.rb and openvox.gemspec
    puts "Setting version to #{version}"

    data = File.read('lib/puppet/version.rb')
    new_data = data.sub(/PUPPETVERSION = '\d+\.\d+\.\d+(\.rc\d+)?'/, "PUPPETVERSION = '#{version}'")
    warn 'Failed to update version in lib/puppet/version.rb' if data == new_data

    File.write('lib/puppet/version.rb', new_data)
  end
end
