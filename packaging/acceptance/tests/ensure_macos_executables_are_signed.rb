test_name 'Ensure puppet executables are codesigned on mac OS' do
  confine :to, :platform => /macos/
  tag 'audit:high'

  agents.each do |agent|
    [
      '/opt/puppetlabs/bin/puppet',
      '/opt/puppetlabs/puppet/bin/puppet',
      '/opt/puppetlabs/puppet/bin/pxp-agent',
      '/opt/puppetlabs/puppet/bin/wrapper.sh'
    ].each do |path|
      step "test #{path}" do
        on(agent, "codesign -vv #{path}") do |result|
          output = result.output

          assert_match(/valid on disk/, output)
          assert_match(/satisfies its Designated Requirement/, output)
        end
      end
    end
  end
end
