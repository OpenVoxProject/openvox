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

    metadata = create_httpmetadata(head, checksum_type) if head.success?

    case head.code
    when 403, 405
      # AMZ presigned URL and puppetserver may return 403
      # instead of 405. Fallback to partial get
      get = partial_get(client, uri)
      metadata = create_httpmetadata(get, checksum_type) if get.success?
    end

    return metadata if metadata.nil? || metadata.checksum

    # No usable checksum headers, so checksum the content itself
    client.get(uri, options: { include_system_store: true }) do |response|
      metadata.collect_from_body(response, checksum_type) if response.success?
    end
    metadata if metadata.checksum
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
