require 'puppet/acceptance/temp_file_utils'

test_name 'Validate openssl version and fips' do
  extend Puppet::Acceptance::TempFileUtils

  tag 'audit:high'

  def openssl_command(host)
    puts "privatebindir=#{host['privatebindir']}"
    "env PATH=\"#{host['privatebindir']}:${PATH}\" openssl"
  end

  def create_bat_wrapper(host, file, command)
    tempfile = get_test_file_path(agent, file)
    create_remote_file(agent, tempfile, command)
    "cmd /c $(cygpath -w #{tempfile})"
  end

  agents.each do |agent|
    openssl = openssl_command(agent)

    step "check openssl version" do
      on(agent, "#{openssl} version -v") do |result|
        assert_match(/^OpenSSL 3\./, result.stdout)
      end
    end

    if agent['template'] =~ /fips/
      step "check fips_enabled fact" do
        on(agent, facter("fips_enabled")) do |result|
          assert_match(/^true/, result.stdout)
        end
      end

      step "check openssl providers" do
        if agent['template'] =~ /^win/
          list_command = create_bat_wrapper(agent, "list_providers.bat", <<~END)
          call "C:\\Program Files\\Puppet Labs\\Puppet\\bin\\environment.bat" %0 %*
          openssl list -providers
          END
        else
          list_command = "#{openssl} list -providers"
        end

        on(agent, list_command) do |result|
          assert_match(Regexp.new(<<~END, Regexp::MULTILINE), result.stdout)
          \s*fips
          \s*name: OpenSSL FIPS Provider
          \s*version: 3.0.9
          \s*status: active
          END
        end
      end

      step "check fipsmodule.cnf" do
        if agent['template'] =~ /^win/
          verify_command = create_bat_wrapper(agent, "verify_fips.bat", <<~END)
          call "C:\\Program Files\\Puppet Labs\\Puppet\\bin\\environment.bat" %0 %*
          openssl fipsinstall -module "%OPENSSL_MODULES%\\fips.dll" -provider_name fips -in "%OPENSSL_CONF_INCLUDE%\\fipsmodule.cnf" -verify
          END
        else
          verify_command = "#{openssl} fipsinstall -module /opt/puppetlabs/puppet/lib/ossl-modules/fips.so -provider_name fips -in /opt/puppetlabs/puppet/ssl/fipsmodule.cnf -verify"
        end

        on(agent, verify_command) do |result|
          assert_match(/VERIFY PASSED/, result.stderr)
        end
      end
    end
  end
end
