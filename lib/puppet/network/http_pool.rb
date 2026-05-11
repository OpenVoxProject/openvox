# frozen_string_literal: true

module Puppet::Network; end

# Allows external HTTP client implementations (e.g., from Puppet Server) to be
# registered for use at runtime. If no custom class is set, the default
# Puppet::HTTP::Client is used.
#
# @api private
module Puppet::Network::HttpPool
  @http_client_class = nil

  def self.http_client_class
    @http_client_class
  end

  def self.http_client_class=(klass)
    @http_client_class = klass
  end
end
