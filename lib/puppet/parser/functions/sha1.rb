# frozen_string_literal: true

require 'digest/sha1'

Puppet::Parser::Functions.newfunction(:sha1, :type => :rvalue, :arity => 1, :doc => "Returns a SHA1 hash value from a provided string.

  *Deprecated:* this function will be removed in a future release. Use the
  `sha256()` function from the `puppetlabs-stdlib` module instead.") do |args|
  Puppet.puppet_deprecation_warning(
    _("The sha1() function is deprecated and will be removed in a future release. " \
      "Use the sha256() function from the puppetlabs-stdlib module instead."),
    key: 'puppet-sha1-function-deprecated'
  )
  Digest::SHA1.hexdigest(args[0])
end
