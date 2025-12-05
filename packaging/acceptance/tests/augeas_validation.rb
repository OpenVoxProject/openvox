skip_test 'non-windows only test' if hosts.any? { |host| host.platform =~ /windows/ }
tag 'audit:high'
test_name 'Augeas Validation' do
  teardown do
    hosts.each do |agent|
      file = <<-EOF
augeas { 'test_ssh':
  lens    => 'Ssh.lns',
  incl    => '/etc/ssh/ssh_config',
  context => '/files/etc/ssh/ssh_config',
  changes => [
    'remove Host testing.testville.nil'
  ]
}
EOF
      on(agent, "puppet apply -e \"#{file}\"")
    end
  end

  hosts.each do |agent|
    step 'validate Augeas binary' do
      on(agent, '/opt/puppetlabs/puppet/bin/augtool --version')
    end
    step 'validate we can apply a resource type augeas' do
      file = <<-EOF
augeas { 'test_ssh':
  lens    => 'Ssh.lns',
  incl    => '/etc/ssh/ssh_config',
  context => '/files/etc/ssh/ssh_config',
  changes => [
    'set Host testing.testville.nil'
  ]
}
EOF
      on(agent, "puppet apply -e \"#{file}\" --detailed-exitcodes", acceptable_exit_codes: [2])
    end
  end
end
