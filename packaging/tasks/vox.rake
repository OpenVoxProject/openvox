# frozen_string_literal: true

namespace :vox do
  desc 'Update the version in preparation for a release'
  task 'version:bump:full', [:version] do |_, args|
    abort 'You must provide a tag.' if args[:version].nil? || args[:version].empty?
    version = args[:version]
    abort "#{version} does not appear to be a valid version string in x.y.z format" unless Gem::Version.correct?(version)

    puts "Setting version to #{version}"

    data = File.read('Rakefile')
    new_data = data.sub(/OPENVOX_AGENT_VERSION = "[^"]+"/, %(OPENVOX_AGENT_VERSION = "#{version}"))
    warn 'Failed to update version in lib/facter/version.rb' if data == new_data

    File.write('Rakefile', new_data)
  end
end
