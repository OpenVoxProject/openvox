require 'open3'

OPENVOX_AGENT_VERSION = "8.22.1"

RED = "\033[31m".freeze
GREEN = "\033[32m".freeze
RESET = "\033[0m".freeze

# Let's ignore rubocop here until such a time as we either muzzle it
# or get these helpers more centralized and tested.
# rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
def run_command(cmd, silent: true, print_command: false, report_status: false)
  cmd_string = cmd.is_a?(String) ? cmd : cmd.join(' ')
  puts "#{GREEN}Running #{cmd_string}#{RESET}" if print_command
  output = ''
  Open3.popen2e(*Array(cmd)) do |_stdin, stdout_stderr, thread|
    stdout_stderr.each do |line|
      puts line unless silent
      output += line
    end
    exitcode = thread.value.exitstatus
    unless exitcode.zero?
      err = "#{RED}Command failed! Command: #{cmd_string}, Exit code: #{exitcode}"
      # Print details if we were running silent
      err += "\nOutput:\n#{output}" if silent
      err += RESET
      abort err
    end
    puts "#{GREEN}Command finished with status #{exitcode}#{RESET}" if report_status
  end
  output.chomp
end
# rubocop:enable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength

Dir.glob(File.join('tasks/**/*.rake')).each { |file| load file }

### Puppetlabs stuff ###
require 'packaging'

load './ext/release-lead.rake'

Pkg::Util::RakeUtils.load_packaging_tasks

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |task|
  # These make the rubocop experience maybe slightly less terrible
  task.options = ['--display-cop-names', '--display-style-guide', '--extra-details']
  # Use Rubocop's Github Actions formatter if possible
  task.formatters << 'github' if ENV['GITHUB_ACTIONS'] == 'true'
end

desc "verify that commit messages match CONTRIBUTING.md requirements"
task(:commits) do
  # Use `GITHUB_BASE_REF` to resolve the merge base
  # ref, which is the common ancestor between the base branch and PR. Then do
  # git log for all of the commits in `HEAD` that are not in the base ref.
  github_base_ref = ENV.fetch('GITHUB_BASE_REF', 'main')
  github_base_ref = 'main' if github_base_ref.empty?
  # There's still something odd here. After action/checkout, 'main' by itself raises
  # objections from git like: `fatal: Not a valid object name main`.
  # but 'origin/main' works. However, if github_base_ref were a sha,
  # origin/SHA would fail as a reference...
  git_merge_base_cmd = ['git', 'merge-base', 'HEAD', "origin/#{github_base_ref}"]
  baseref = run_command(git_merge_base_cmd)
  commits = "#{baseref}..HEAD"
  git_log_cmd = ['git', 'log', '--no-merges', '--pretty=%s', commits]
  commit_lines = run_command(git_log_cmd, silent: false, print_command: true)

  commit_lines.each_line do |commit_summary|
    error_message = <<~HEREDOC
      \n\n\n\tThis commit summary didn't match CONTRIBUTING.md guidelines:
      \n\t\t#{commit_summary}
      \tThe commit summary (i.e. the first line of the commit message) should start with one of:
      \t\t(docs)
      \t\t(maint)
      \t\t(packaging)
      \t\t(<gh-#>) (An existing github ticket ref)
      \n\tThis test for the commit summary is case-insensitive.\n
    HEREDOC

    commit_format_regex = /
      ^\((?:maint|doc|docs|packaging|(([[:alpha:]]+)-(\d+)))\)|
      revert|bumping|merge|promoting
    /xi
    match = commit_summary.match(commit_format_regex)
    raise error_message if match.nil?

    ticket = match[1]
    next if ticket.nil?
    project = match[2]
    # Could be an old PUP- or other Jira, and while there is still a
    # https://puppet.atlassian.net archive, determining that a
    # particular ticket does not exist is more involved that getting a
    # 200 on a call like https://puppet.atlassian.net/browse/PUP-1234
    next if project != 'gh'
    ticket_number = match[3]

    require 'net/http'
    require 'uri'
    uri = URI.parse("https://github.com/openvoxproject/openvox-agent/issues/#{ticket_number}")
    response = Net::HTTP.get_response(uri)
    if response.code != "200"
      ticket_error = "\t#{RED}Did not find a ticket matching #{ticket} at #{uri}#{RESET}\n\n"
      raise error_message + ticket_error
    end
  end
  puts "#{GREEN}All commit messages match the guidelines!#{RESET}"
end

begin
  require "github_changelog_generator/task"

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.header = <<~HEADER.chomp
    # Changelog

    All notable changes to this project will be documented in this file.
    HEADER
    config.user = "openvoxproject"
    config.project = "openvox-agent"
    config.exclude_labels = %w[dependencies duplicate question invalid wontfix wont-fix modulesync skip-changelog]
    config.future_release = OPENVOX_AGENT_VERSION
    config.exclude_tags_regex = /\A7\./
  end
rescue LoadError
  task :changelog do
    abort("Run `bundle install --with release` to install the `github_changelog_generator` gem.")
  end
end

desc 'Prepare for a release'
task 'release:prepare' => [:changelog]
