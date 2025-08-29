test_name 'Ensure puppet facts can use facter' do

  require 'puppet/acceptance/common_utils'

  agents.each do |agent|
    step 'test puppet facts with correct facter version' do
      on(agent, puppet('facts'), :acceptable_exit_codes => [0]) do |result|
        facter_major_version =  Integer(JSON.parse(result.stdout)["facterversion"].split('.').first)
        assert(5 >= facter_major_version, "wrong facter version")
      end
    end

    step "test puppet facts with facter has all the dependencies installed" do
      on(agent, puppet('facts --debug'), :acceptable_exit_codes => [0]) do |result|
        if agent['platform'] =~ /win/
          # exclude augeas as it is not provided on Windows
          unresolved_fact = result.stdout.match(/(resolving fact (?!augeas).+\, but)/)
        else
          unresolved_fact = result.stdout.match(/(resolving fact .+\, but)/)
        end

        assert_nil(unresolved_fact, "missing dependency for facter from: #{unresolved_fact.inspect}")
      end
    end

    step "test that stderr is empty on puppet facts'" do
      on(agent, puppet('facts'), :acceptable_exit_codes => [0]) do |result|
        assert_empty(result.stderr, "Expected `puppet facts` stderr to be empty")
      end
    end
  end
end

