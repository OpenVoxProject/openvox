# frozen_string_literal: true

require_relative '../../puppet/util/feature'

# PSON has been removed. This feature is always false.
Puppet.features.add(:pson) { false }
