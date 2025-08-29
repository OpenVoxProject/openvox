test_name 'PA-2768: Extend manpath instead of overriding it' do

  tag 'audit:low',
    'audit:acceptance'

  # shellpath scripts are only installed on linux, however macos knows how to find
  # man directories relative to the existing path
  confine :except, :platform => ['windows', 'aix', 'solaris']

  agents.each do |agent|
    man_command = nil

    step 'test for man command' do
      on(agent, 'command -v man', :acceptable_exit_codes => [0, 1]) do |result|
        man_command = result.stdout.chomp
      end
    end

    skip_test "man command not found on #{agent.hostname} (#{agent.platform})" unless man_command

    step 'test if we have puppet manpages' do
      on(agent, "#{man_command} puppet")
    end

    step 'test if we have unix manpages' do
      on(agent, "#{man_command} ls")
    end
  end
end
