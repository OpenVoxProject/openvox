test_name "#6541: checksum-like file content is managed literally" do

tag 'audit:high',
    'audit:integration', # file type and file bucket interop
    'shard:group3' # For splitting out groups of tests for slow test runners

  # Historically, a content value that looked like a checksum
  # ('{sha256}...', '{md5}...') triggered implicit filebucket retrieval,
  # which made it impossible to manage a file whose literal content looks
  # like a checksum, and truncated the target when the bucket could not
  # supply the hash (the original #6541). That behavior was removed in
  # OpenVox 9 (openvox#170): content is now always literal.

  agents.each do |agent|
    target = agent.tmpfile('6541-target')

    step "write initial file content" do
      manifest = "file { '#{target}': content => 'some text' }"
      apply_manifest_on(agent, manifest)
    end

    step "checksum-like content that is not a valid hash is written literally" do
      manifest = "file { '#{target}': content => '{sha256}notahash' }"
      apply_manifest_on(agent, manifest)
      on(agent, "cat #{target}") do |result|
        assert_equal('{sha256}notahash', result.stdout, "#{agent}: expected the literal content to be written")
      end
    end

    step "well-formed checksum content is also written literally, not resolved from a bucket" do
      manifest = "file { '#{target}': content => '{sha256}e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', backup => 'puppet' }"
      apply_manifest_on(agent, manifest)
      on(agent, "cat #{target}") do |result|
        assert_equal('{sha256}e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                     result.stdout,
                     "#{agent}: expected the literal checksum string, not filebucket content")
      end
    end
  end
end
