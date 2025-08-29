require 'fileutils'

namespace :vox do
  desc 'Build vanagon project with Docker'
  task :build, [:project, :platform] do |_, args|
    # This is not currently really any different than 'bundle exec build puppet-agent <platform> --engine docker',
    # but adding this machinery so we can make it fancier later and have a common way to build
    # locally and in an action.
    args.with_defaults(project: 'puppet-agent')
    project = args[:project]

    ENV['SOURCE_DATE_EPOCH'] ||= `git log -1 --format=%ct`.chomp

    abort 'You must provide a platform.' if args[:platform].nil? || args[:platform].empty?
    platform = args[:platform]

    engine = platform =~ /^(osx|windows)-/ ? 'local' : 'docker'
    cmd = "bundle exec build #{project} #{platform} --engine #{engine}"

    run_command(cmd, silent: false, print_command: true, report_status: true)
  end
end
