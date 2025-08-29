test_name 'PUP-8351: Ensure pip provider works with RHSCL python' do
  confine :to, :platform => /centos-(6|7)-x86_64/
  tag 'audit:medium',
      'audit:acceptance'

  teardown do
      on agent, 'yum remove python27-python-pip -y'
  end

  step 'install and enable RHSCL python' do
    on agent, 'yum install centos-release-scl -y'
    on agent, 'yum install python27-python-pip -y'
  end

  step 'With with the SCL python enabled: Attempt \'resource package\' with a python package and the pip provider' do
    on(agent, 'source /opt/rh/python27/enable && puppet resource package vulture ensure=present provider=\'pip\'')
  end
end
