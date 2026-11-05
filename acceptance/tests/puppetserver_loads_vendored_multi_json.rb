# The agent installs multi_json into the vendor gem directory that puppetserver
# also loads from. This test ONLY checks that puppetserver's JRuby can load
# that copy, because gem version bumps in puppet-runtime have broken it before
# (puppet-runtime#156, puppet-runtime#333). It does not test multi_json itself.
test_name 'puppetserver can load the multi_json gem shipped by the agent'

tag 'server',
    'shard:group2'

on(master, %q{/opt/puppetlabs/server/bin/puppetserver ruby -e 'require "multi_json"; puts MultiJson.dump("loaded" => true)'}) do |result|
  assert_match(/\{"loaded":true\}/, result.stdout)
end
