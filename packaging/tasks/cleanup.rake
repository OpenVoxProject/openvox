require 'fileutils'

namespace :vox do
  desc 'Cleanup after puppet-runtime compile'
  task :cleanup, [:platform] do |_, args|
    abort 'You must provide a platform.' if args[:platform].nil? || args[:platform].empty?
    platform = args[:platform]

    if platform =~ /^windows-/
      FileUtils.rm_rf('C:/ProgramFiles64Folder')
    elsif platform =~ /^osx-/
      FileUtils.rm_rf('/opt/puppetlabs')
      FileUtils.rm_rf('/private/etc/puppetlabs')
    else
      FileUtils.rm_rf('/opt/puppetlabs')
      FileUtils.rm_rf('/etc/puppetlabs')
    end
  end
end
