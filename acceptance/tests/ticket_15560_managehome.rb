test_name "#15560: Manage home directories"

tag 'audit:high',
    'audit:refactor',  # Use block style `test_namme`
                       # refactor to be OS agnostic and added to the resource/user
                       # tests. managehome is currently not covered there.
    'audit:acceptance',
    'shard:group2' # For splitting out groups of tests for slow test runners

confine :to, :platform => 'windows'

username = "pl#{rand(99999).to_i}"

manifest_present = <<-EOM
user { '#{username}':
  ensure     => present,
  managehome => true,
  password   => 'Password123!!',
}
EOM

manifest_absent = <<-EOM
user { '#{username}':
  ensure     => absent,
  managehome => true,
}
EOM

agents.each do |host|
  on(host, puppet_apply, :stdin => manifest_present)

  homedir = "C:/Users/#{username}"
  on(host, "test -d '#{homedir}'")

  on(host, puppet_apply, :stdin => manifest_absent)
  on(host, "test ! -d '#{homedir}'")
end
