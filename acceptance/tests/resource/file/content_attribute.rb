test_name "Content Attribute"
tag 'audit:high',
    'audit:refactor',   # Use block stype test_name
    'audit:acceptance',
    'shard:group3' # For splitting out groups of tests for slow test runners

agents.each do |agent|
  target = agent.tmpfile('content_file_test')

  step "Ensure the test environment is clean"
  on agent, "rm -f #{target}"

  step "Content Attribute: using raw content"

  checksums_fips = ['sha256', 'sha256lite']
  checksums_no_fips = ['sha256', 'sha256lite', 'md5', 'md5lite']

  if on(agent, facter("fips_enabled")).stdout =~ /true/
    checksums = checksums_fips
  else
    checksums = checksums_no_fips
  end

  manifest = "file { '#{target}': content => 'This is the test file content', ensure => present }"
  manifest += checksums.collect {|checksum_type|
    "file { '#{target+checksum_type}': content => 'This is the test file content', ensure => present, checksum => #{checksum_type} }"
  }.join("\n")
  apply_manifest_on(agent, manifest) do |result|
    checksums.each do |checksum_type|
      refute_match(/content changed/, result.stdout, "#{agent}: shouldn't have overwrote #{target+checksum_type}")
    end
  end

  on(agent, "cat #{target}") do |result|
    assert_match(/This is the test file content/, result.stdout, "File content not matched on #{agent}") unless agent['locale'] == 'ja'
  end

  step "Content Attribute: illegal timesteps"
  ['mtime', 'ctime'].each do |checksum_type|
    manifest = "file { '#{target+checksum_type}': content => 'This is the test file content', ensure => present, checksum => #{checksum_type} }"
    apply_manifest_on(agent, manifest, :acceptable_exit_codes => [1]) do |result|
      assert_match(/Error: Validation of File\[#{target+checksum_type}\] failed: You cannot specify content when using checksum '#{checksum_type}'/, result.stderr, "#{agent}: expected failure") unless agent['locale'] == 'ja'
    end
  end

  step "Ensure the test environment is clean"
  on(agent, "rm -f #{target}")

  # The "checksum from filebucket" scenario was removed along with the
  # implicit filebucket retrieval for checksum-like content values
  # (openvox#170); content is now always managed literally. See
  # ticket_6541_invalid_filebucket_files.rb for coverage of the literal
  # behavior.
end
