# frozen_string_literal: true

require_relative '../../../puppet/file_serving/http_metadata'
require_relative '../../../puppet/indirector/generic_http'
require_relative '../../../puppet/indirector/file_metadata'
require 'net/http'

class Puppet::Indirector::FileMetadata::Http < Puppet::Indirector::GenericHttp
  desc "Retrieve file metadata from a remote HTTP server."

  include Puppet::FileServing::TerminusHelper

  def find(request)
    checksum_type = request.options[:checksum_type]
    # See URL encoding comment in Puppet::Type::File::ParamSource#chunk_file_from_source
    uri = URI(request.uri)
    client = Puppet.runtime[:http]
    head = client.head(uri, options: { include_system_store: true })

    metadata = create_httpmetadata(head, checksum_type)
    return metadata if metadata.checksum

    # If no checksum headers were available, fetch the content to compute a checksum
    get = client.get(uri, options: { include_system_store: true })
    return nil unless get.success?

    # Compute checksum from the content
    content = get.body
    checksum_type ||= Puppet[:digest_algorithm].to_sym
    checksum = "{#{checksum_type}}" + Digest.const_get(checksum_type.to_s.upcase).hexdigest(content)

    metadata.checksum = checksum
    metadata.checksum_type = checksum_type
    metadata
  end

  def search(request)
    raise Puppet::Error, _("cannot lookup multiple files")
  end

  private

  def partial_get(client, uri)
    client.get(uri, headers: { 'Range' => 'bytes=0-0' }, options: { include_system_store: true })
  end

  def create_httpmetadata(http_request, checksum_type)
    metadata = Puppet::FileServing::HttpMetadata.new(http_request)
    metadata.checksum_type = checksum_type if checksum_type
    metadata.collect
    metadata
  end
end
