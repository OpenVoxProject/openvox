require 'fileutils'

namespace :vox do
  desc 'Build vanagon project with Docker'
  task :build, [:project, :platform] do |_, args|
    args.with_defaults(project: 'openvox-agent')
    project = args[:project]

    ENV['SOURCE_DATE_EPOCH'] ||= `git log -1 --format=%ct`.chomp

    abort 'You must provide a platform.' if args[:platform].nil? || args[:platform].empty?
    platform = args[:platform]
    os, _ver, arch = platform.match(/^(\w+)-([\w|\.]+)-(\w+)$/).captures

    engine = platform =~ /^(macos|windows)-/ ? 'local' : 'docker'
    cmd = "bundle exec build #{project} #{platform} --engine #{engine}"

    Dir.chdir('packaging') do
      run_command(cmd, silent: false, print_command: true, report_status: true)
    end
  end
end
