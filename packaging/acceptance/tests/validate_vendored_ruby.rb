require 'puppet/acceptance/common_utils.rb'
require 'puppet/acceptance/temp_file_utils'
extend Puppet::Acceptance::CommandUtils

def package_installer(agent)
  # for some reason, beaker does not have a configured package installer
  # for AIX so we manually set up the package installer for it.
  if agent['platform'] =~ /aix/
    lambda { |package| on(agent, "rm -f `basename #{package}` && curl -O #{package} && rpm -Uvh `basename #{package}`") }
  else
    lambda { |package| agent.install_package(package) }
  end
end

def setup_build_environment(agent)
  # We set the gem path for install here to our internal shared vendor
  # path. This allows us to verify that our Ruby is able to read from
  # this path when listing / loading gems in the test below.

  # The sqlite3 gem >= 1.5.0 bundles libsqlite3, which breaks some tests
  # We add `--enable-system-libraries` to use system libsqlite3
  gem_install_sqlite3 = "env GEM_HOME=/opt/puppetlabs/puppet/lib/ruby/vendor_gems " + gem_command(agent) + " install sqlite3 -- --enable-system-libraries"
  install_package_on_agent = package_installer(agent)
  rubygems_version = agent['platform'] =~ /aix-7\.2/ ? '3.4.22' : ''
  on(agent, "#{gem_command(agent)} update --system #{rubygems_version}")

  case agent['platform']
  when /aix/
    # sed on AIX does not support in place edits or delete
    on(agent, "sed '/\"warnflags\"/d' /opt/puppetlabs/puppet/lib/ruby/3.2.0/powerpc-aix7.2.0.0/rbconfig.rb > no_warnflags_rbconfig.rb")
    on(agent, "cp no_warnflags_rbconfig.rb /opt/puppetlabs/puppet/lib/ruby/3.2.0/powerpc-aix7.2.0.0/rbconfig.rb")
    # use pl-build-tools' gcc on AIX machines
    gem_install_sqlite3 = "export PATH=\"/opt/pl-build-tools/bin:$PATH\" && #{gem_install_sqlite3}"
  when /solaris-11(.4|)-i386/
    # We need to install a newer compiler to build native extensions,
    # so we use a newer GCC from OpenCSW
    vanagon_noask_contents = "mail=\n"\
      "instance=overwrite\n"\
      "partial=nocheck\n"\
      "runlevel=nocheck\n"\
      "idepend=nocheck\n"\
      "rdepend=nocheck\n"\
      "space=quit\n"\
      "setuid=nocheck\n"\
      "conflict=nocheck\n"\
      "action=nocheck\n"\
      "basedir=default"
    vanagon_noask_path = "/var/tmp/vanagon-noask"
    on(agent, "echo \"#{vanagon_noask_contents}\" > #{vanagon_noask_path}")

    vanagon_pkgutil_contents = "mirror=https://artifactory.delivery.puppetlabs.net/artifactory/generic__remote_opencsw_mirror/testing"
    vanagon_pkgutil_path = "/var/tmp/vanagon-pkgutil.conf"
    on(agent, "echo \"#{vanagon_pkgutil_contents}\" > #{vanagon_pkgutil_path}")

    on(agent, 'pkgadd -n -a /var/tmp/vanagon-noask -d http://get.opencsw.org/now all')
    on(agent, '/opt/csw/bin/pkgutil --config=/var/tmp/vanagon-pkgutil.conf -y -i gcc5core')

    gem_install_sqlite3 = "export PATH=\"/opt/csw/bin:$PATH\" && #{gem_install_sqlite3}"
  when /solaris-11-sparc/
    install_package_on_agent.call("developer/gcc-48")
    gem_install_sqlite3 = "export PATH=\"/usr/gcc/4.8/bin:$PATH\" && #{gem_install_sqlite3}"
  end

  gem_install_sqlite3
end

def install_dependencies(agent)
  return if agent['platform'] =~ /osx|solaris-11|sparc/

  install_package_on_agent = package_installer(agent)
  dependencies = {
    'apt-get' => ['gcc', 'make', 'libsqlite3-dev'],
    'yum' => ['gcc', 'make', 'sqlite-devel'],
    'zypper' => ['gcc', 'sqlite3-devel'],
    'opt/csw/bin/pkgutil' => ['sqlite3', 'libsqlite3_dev'],
    'rpm' => [
      'http://pl-build-tools.delivery.puppetlabs.net/aix/6.1/ppc/pl-gcc-5.2.0-11.aix6.1.ppc.rpm',
      'http://osmirror.delivery.puppetlabs.net/AIX_MIRROR/pkg-config-0.19-6.aix5.2.ppc.rpm',
      'http://osmirror.delivery.puppetlabs.net/AIX_MIRROR/info-4.6-1.aix5.1.ppc.rpm',
      'https://artifactory.delivery.puppetlabs.net/artifactory/generic__buildsources/buildsources/readline-7.0-3.aix5.1.ppc.rpm',
      'https://artifactory.delivery.puppetlabs.net/artifactory/generic__buildsources/buildsources/readline-devel-7.0-3.aix5.1.ppc.rpm',
      'https://artifactory.delivery.puppetlabs.net/artifactory/generic__buildsources/buildsources/sqlite-3.20.0-1.aix5.1.ppc.rpm',
      'https://artifactory.delivery.puppetlabs.net/artifactory/generic__buildsources/buildsources/sqlite-devel-3.20.0-1.aix5.1.ppc.rpm'
    ]
  }

  provider = dependencies.keys.find do |_provider|
    result = on(agent, "which #{_provider}", :accept_all_exit_codes => true)
    # the `which` command on Solaris returns a 0 exit code even when the file
    # does not exist
    agent['platform'] =~ /solaris/ ?
       result.stdout.chomp !~ /no #{_provider}/
     : result.exit_code.zero?
  end
  providers = dependencies.keys.join(', ')
  assert(provider, "The agent does not have one of #{providers} as its package provider")

  dependencies[provider].each do |dependency|
    install_package_on_agent.call(dependency)
  end
end

test_name 'PA-1319: Validate that the vendored ruby can load gems and is configured correctly' do

  step "'gem list' displays a decent list of gems" do
    minimum_number_of_gems = 3
    # \d+\.\d+\.\d+ describes the gem version
    gem_re = /[\w-]+ \(\d+\.\d+\.\d+(?:, \d+\.\d+\.\d+)*\)/

    agents.each do |agent|
      gem = gem_command(agent)
      listed_gems = on(agent, "#{gem} list").stdout.chomp.scan(gem_re)
      assert(listed_gems.size >= minimum_number_of_gems, "'gem list' fails to list the available gems (i.e., the rubygems environment is not sane)")
    end
  end

  step "vendored ruby successfully loads gems" do
    agents.each do |agent|
      irb = irb_command(agent)

      ['hocon', 'deep_merge', 'puppet/resource_api'].each do |gem|
        if agent['platform'] =~ /windows*/
          # Although beaker can set a PATH for puppet-agent on Windows, it isn't
          # able to set up the environment for the purpose of loading gems this
          # way; See BKR-1445 and BKR-986. As a workaround, run the environment
          # script before requiring the gem. We're using `ruby -r` instead of
          # irb here because `cmd /c` will only run one argument command before
          # returning to cygwin (additional arguments will be treated as bash)
          # and using irb introduces too many quotes.
          cmd = "env PATH=\"#{agent['privatebindir']}:${PATH}\" cmd /c \"environment.bat && ruby -r#{gem} -e 'puts true'\""
          stdout = on(agent, cmd).stdout.chomp
          assert_match(/true/, stdout, "ruby failed to require the #{gem} gem")
        else
          stdout = on(agent, "echo \"require '#{gem}'\" | #{irb}").stdout.chomp
          assert_match(/true/, stdout, "'irb' failed to require the #{gem} gem")
        end
      end
    end
  end

  step "'gem install' successfully installs a gem with native extensions" do
    agents_to_skip = select_hosts({:platform => [/windows/, /cisco/, /eos/, /cumulus/, /aix-7.3-power/]}, agents)
    agents_to_test = agents - agents_to_skip
    agents_to_test.each do |agent|
      gem_install_sqlite3 = setup_build_environment(agent)

      # Upgrade the AlmaLinux release package for newer keys until our image is updated (RE-16096)
      on(agent, 'dnf -y upgrade almalinux-release') if on(agent, facter('os.name')).stdout.strip == 'AlmaLinux'

      install_dependencies(agent)
      on(agent, gem_install_sqlite3)

      gem = gem_command(agent)
      listed_gems = on(agent, "#{gem} list").stdout.chomp
      assert_match(/sqlite3/, listed_gems, "'gem install' failed to build the sqlite3 gem")
    end
  end

  step "'gem update --system' keeps vendor_gems still in path" do
    agents_to_skip = select_hosts({:platform => [/windows/, /cisco/, /eos/, /cumulus/]}, agents)
    agents_to_test = agents - agents_to_skip
    agents_to_test.each do |agent|
      rubygems_version = agent['platform'] =~ /aix-7\.2/ ? '3.4.22' : ''
      on(agent, "/opt/puppetlabs/puppet/bin/gem update --system #{rubygems_version}")
      list_env = on(agent, "/opt/puppetlabs/puppet/bin/gem env").stdout.chomp
      unless list_env.include?("/opt/puppetlabs/puppet/lib/ruby/vendor_gems")
        fail_test("Failed to keep vendor_gems directory in GEM_PATH!")
      end
    end
  end
end
