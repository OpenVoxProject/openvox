# This test ONLY checks if r10k is executable without gem version conflicts,
# due to running into problems here with gem version bumps in puppet-runtime.
# It does not test r10k functionality itself.
test_name 'Can install and execute r10k with no gem conflicts'

# On pre-8.23.0, we already had fast_gettext installed to the
# /opt/puppetlabs/puppet/lib/ruby/vendor_gems/gems directory, so
# when r10k was installed, it would not install fast_gettext to
# /opt/puppetlabs/puppet/lib/ruby/gems/3.2.0/gems. Then, upon agent
# upgrade, that version in vendor_gems was replaced with 4.1.0 and
# since r10k has a dependency on gettext-setup which pins
# fast_gettext to ~> 2.1, it would fail. Below simulates
# this condition by removing any fast_gettext installed automatically
# via 'gem install r10k'.
#
# To test this more robustly, we'll want to implement this test in an upgrade
# test suite instead.
on(master, '/opt/puppetlabs/puppet/bin/gem install r10k')
on(master, 'rm -rf "/opt/puppetlabs/puppet/lib/ruby/gems/3.2.0/gems/fast_gettext*"')
on(master, 'rm -f /opt/puppetlabs/puppet/lib/ruby/gems/3.2.0/specifications/fast_gettext*.gemspec')
on(master, '/opt/puppetlabs/puppet/bin/r10k')

teardown { on(master, '/opt/puppetlabs/puppet/bin/gem uninstall -ax r10k') }
