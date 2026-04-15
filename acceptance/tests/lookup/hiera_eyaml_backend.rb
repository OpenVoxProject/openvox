test_name 'hiera-eyaml backend resolves encrypted values via eyaml_lookup_key' do
  require 'puppet/acceptance/environment_utils.rb'
  extend Puppet::Acceptance::EnvironmentUtils
  require 'puppet/acceptance/temp_file_utils.rb'
  extend Puppet::Acceptance::TempFileUtils

  tag 'audit:high',
      'audit:acceptance'

  app_type        = File.basename(__FILE__, '.*')
  tmp_environment = mk_tmp_environment_with_teardown(master, app_type)
  tmp_environmentpath = "#{environmentpath}/#{tmp_environment}"

  confdir       = puppet_config(master, 'confdir', section: 'master')
  eyaml_keysdir = "#{confdir}/eyaml-keys"
  private_key   = "#{eyaml_keysdir}/private_key.pkcs7.pem"
  public_key    = "#{eyaml_keysdir}/public_key.pkcs7.pem"

  teardown do
    step 'remove eyaml keys' do
      on(master, "rm -rf #{eyaml_keysdir}", :acceptable_exit_codes => [0, 1])
    end

    agents.each do |agent|
      on(agent, puppet('config print lastrunfile')) do |command_result|
        agent.rm_rf(command_result.stdout)
      end
    end
  end

  # hiera-eyaml ships preinstalled in both the openvox-agent and openvox-server
  # so no gem install is needed. The eyaml CLI lives at
  # /opt/puppetlabs/puppet/bin/eyaml from the agent gem.
  step 'generate PKCS7 keypair with the eyaml CLI' do
    on(master, "mkdir -p #{eyaml_keysdir}")
    on(master, "/opt/puppetlabs/puppet/bin/eyaml createkeys " \
                "--pkcs7-private-key=#{private_key} " \
                "--pkcs7-public-key=#{public_key}")
    # puppetserver runs as the puppet user and must be able to read the private key.
    # Root (the beaker connection user) bypasses mode bits, so puppet lookup on the primary still works.
    on(master, "chown -R puppet:puppet #{eyaml_keysdir}")
    on(master, "chmod 0500 #{eyaml_keysdir}")
    on(master, "chmod 0400 #{private_key}")
    on(master, "chmod 0444 #{public_key}")
  end

  encrypted_secret = nil
  encrypted_password = nil
  step 'encrypt distinct values using the eyaml CLI' do
    encrypt_cmd = lambda do |plaintext|
      result = on(master, "/opt/puppetlabs/puppet/bin/eyaml encrypt " \
                           "--pkcs7-public-key=#{public_key} " \
                           "--output=string --string='#{plaintext}'")
      ciphertext = result.stdout.strip
      # Restrict to base64 characters so embedded newlines or whitespace fail loudly here
      # rather than silently producing invalid YAML when interpolated below.
      assert_match(/\AENC\[PKCS7,[A-Za-z0-9+\/=]+\]\z/, ciphertext,
                   "eyaml encrypt did not produce a single-line PKCS7 block: #{ciphertext.inspect}")
      ciphertext
    end

    encrypted_secret   = encrypt_cmd.call('super_secret_value')
    encrypted_password = encrypt_cmd.call('nested_password_value')
    assert(encrypted_secret != encrypted_password,
           'PKCS7 ciphertexts for distinct plaintexts collided; encryption is not randomized as expected')
  end

  step 'configure environment hiera.yaml to use eyaml_lookup_key and write data files' do
    on(master, "mkdir -p #{tmp_environmentpath}/data")
    on(master, "mkdir -p #{tmp_environmentpath}/modules/eyaml_test/manifests")

    create_remote_file(master, "#{tmp_environmentpath}/hiera.yaml", <<-HIERA)
---
version: 5
hierarchy:
  - name: 'Encrypted secrets (eyaml backend)'
    lookup_key: eyaml_lookup_key
    paths:
      - 'secrets.eyaml'
    options:
      pkcs7_private_key: #{private_key}
      pkcs7_public_key:  #{public_key}
  - name: 'Plain YAML'
    data_hash: yaml_data
    paths:
      - 'common.yaml'
    HIERA

    # secrets.eyaml exercises three documented hiera-eyaml shapes in one file:
    # a top-level encrypted scalar, an encrypted value nested inside a hash,
    # a plain (unencrypted) value living alongside encrypted ones, and a class
    # parameter key (eyaml_test::api_key) for automatic class-parameter lookup.
    create_remote_file(master, "#{tmp_environmentpath}/data/secrets.eyaml", <<-EYAML)
---
eyaml_secret: #{encrypted_secret}
eyaml_nested:
  password: #{encrypted_password}
  username: 'plain_user_in_eyaml_file'
eyaml_plain_in_eyaml: 'mixed_plaintext_value'
eyaml_test::api_key: #{encrypted_secret}
EYAML

    create_remote_file(master, "#{tmp_environmentpath}/data/common.yaml", <<-YAML)
---
plain_value: 'plaintext_from_yaml'
    YAML

    create_remote_file(master, "#{tmp_environmentpath}/modules/eyaml_test/manifests/init.pp", <<-MANIFEST)
class eyaml_test(String $api_key) {
  notify { "param=${api_key}": }
}
    MANIFEST

    create_sitepp(master, tmp_environment, <<-SITE)
      notify { "eyaml=${lookup('eyaml_secret')}": }
      notify { "plain=${lookup('plain_value')}": }
      notify { "nested_pw=${lookup('eyaml_nested')['password']}": }
      notify { "nested_user=${lookup('eyaml_nested')['username']}": }
      notify { "mixed=${lookup('eyaml_plain_in_eyaml')}": }
      include eyaml_test
    SITE

    on(master, "chmod -R #{PUPPET_CODEDIR_PERMISSIONS} #{tmp_environmentpath}")
  end

  step 'puppet lookup decrypts a top-level eyaml value' do
    on(master, puppet('lookup', "--environment #{tmp_environment}", 'eyaml_secret'),
       :accept_all_exit_codes => true) do |result|
      assert_equal(0, result.exit_code,
                   "puppet lookup eyaml_secret failed (#{result.exit_code}): #{result.stderr}")
      assert_match(/super_secret_value/, result.stdout,
                   'puppet lookup did not decrypt the top-level eyaml value')
      refute_match(/ENC\[PKCS7/, result.stdout,
                   'puppet lookup returned ciphertext for the top-level eyaml value')
    end
  end

  step 'puppet lookup decrypts an eyaml value nested inside a hash and preserves plaintext siblings' do
    on(master, puppet('lookup', "--environment #{tmp_environment}", 'eyaml_nested'),
       :accept_all_exit_codes => true) do |result|
      assert_equal(0, result.exit_code,
                   "puppet lookup eyaml_nested failed (#{result.exit_code}): #{result.stderr}")
      assert_match(/nested_password_value/, result.stdout,
                   'puppet lookup did not decrypt the nested eyaml value')
      assert_match(/plain_user_in_eyaml_file/, result.stdout,
                   'puppet lookup lost the plaintext sibling inside an eyaml hash')
      refute_match(/ENC\[PKCS7/, result.stdout,
                   'puppet lookup returned ciphertext instead of the decrypted nested value')
    end
  end

  step 'puppet lookup returns plaintext values stored in an eyaml file unchanged' do
    on(master, puppet('lookup', "--environment #{tmp_environment}", 'eyaml_plain_in_eyaml'),
       :accept_all_exit_codes => true) do |result|
      assert_equal(0, result.exit_code,
                   "puppet lookup eyaml_plain_in_eyaml failed (#{result.exit_code}): #{result.stderr}")
      assert_match(/mixed_plaintext_value/, result.stdout,
                   'puppet lookup did not return a plaintext value from an eyaml-backed file')
    end
  end

  step 'puppet lookup still resolves plain YAML data alongside the eyaml hierarchy' do
    on(master, puppet('lookup', "--environment #{tmp_environment}", 'plain_value'),
       :accept_all_exit_codes => true) do |result|
      assert_equal(0, result.exit_code,
                   "puppet lookup plain_value failed (#{result.exit_code}): #{result.stderr}")
      assert_match(/plaintext_from_yaml/, result.stdout,
                   'puppet lookup did not return the plain yaml value')
    end
  end

  with_puppet_running_on(master, {}) do
    agents.each do |agent|
      step "agent run on #{agent} receives decrypted values and exercises class-parameter automatic lookup" do
        on(agent, puppet('agent', "-t --environment #{tmp_environment}"),
           :accept_all_exit_codes => true) do |result|
          assert_equal(2, result.exit_code,
                       "agent run did not apply changes (#{result.exit_code}): #{result.stderr}")
          assert_match(/eyaml=super_secret_value/, result.stdout,
                       'agent did not receive the decrypted top-level eyaml value')
          assert_match(/nested_pw=nested_password_value/, result.stdout,
                       'agent did not receive the decrypted nested eyaml value')
          assert_match(/nested_user=plain_user_in_eyaml_file/, result.stdout,
                       'agent did not receive a plaintext sibling inside an eyaml hash')
          assert_match(/mixed=mixed_plaintext_value/, result.stdout,
                       'agent did not receive a plaintext value stored in an eyaml file')
          assert_match(/plain=plaintext_from_yaml/, result.stdout,
                       'agent did not receive the plain yaml value')
          assert_match(/param=super_secret_value/, result.stdout,
                       'class parameter automatic lookup did not decrypt eyaml_test::api_key')
          refute_match(/ENC\[PKCS7/, result.stdout,
                       'agent received raw ciphertext instead of the decrypted value')
        end
      end
    end
  end
end
