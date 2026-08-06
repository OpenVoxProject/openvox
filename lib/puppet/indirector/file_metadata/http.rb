# frozen_string_literal: true

require_relative '../../../puppet/file_serving/http_metadata'
require_relative '../../../puppet/indirector/generic_http'
require_relative '../../../puppet/indirector/file_metadata'
require_relative '../../../puppet/util/checksums'
require 'net/http'

class Puppet::Indirector::FileMetadata::Http < Puppet::Indirector::GenericHttp
  desc "Retrieve file metadata from a remote HTTP server."

  include Puppet::FileServing::TerminusHelper
  include Puppet::Util::Checksums

  def find(request)
    checksum_type = request.options[:checksum_type]
    # See URL encoding comment in Puppet::Type::File::ParamSource#chunk_file_from_source
    uri = URI(request.uri)
    client = Puppet.runtime[:http]
    head = client.head(uri, options: { include_system_store: true })

    return verify(client, uri, checksum_type, create_httpmetadata(head, checksum_type)) if head.success?

    case head.code
    when 403, 405
      # AMZ presigned URL and puppetserver may return 403
      # instead of 405. Fallback to partial get
      get = partial_get(client, uri)
      return verify(client, uri, checksum_type, create_httpmetadata(get, checksum_type)) if get.success?
    end

    nil
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

  # Headers gave us nothing usable. If the caller wants real content
  # verification (i.e. didn't explicitly ask for mtime/ctime/none), earn a
  # checksum by downloading the body once here and hashing it as it
  # streams by, without keeping the bytes around: if a rewrite turns out
  # to be needed, the normal content fetch downloads it again. That costs
  # one extra request only when the content has actually changed, and
  # avoids holding an open tempfile for the far more common unchanged
  # case, which a long-running agent would otherwise accumulate across
  # many catalog runs.
  #
  # A failed or errored GET here is a real failure, not "unchanged": a
  # non-success response returns nil, exactly like the HEAD request above
  # already does on failure, and any raised error (network, TLS, etc.)
  # propagates rather than being swallowed -- silently treating "we
  # couldn't verify" as "unchanged" would hide the failure entirely,
  # whereas before this method existed, that same failure would have
  # surfaced when the always-different fabricated mtime forced a content
  # fetch anyway.
  def verify(client, uri, checksum_type, metadata)
    return metadata if metadata.checksum_type != :none

    # mtime/ctime normally track changes, but with no time header from the
    # server there is nothing to compare against, so the file can never be
    # detected as changed -- say so instead of degrading silently. An
    # explicit :none (or no requested type at all) already means
    # "don't verify", so those stay quiet.
    if checksum_type == :mtime || checksum_type == :ctime
      Puppet.warning(_("Source %{uri} supplied no usable HTTP validation headers; with checksum => %{type} the file will never be detected as changed. Use a content digest checksum type to detect changes from this source.") % { uri: uri, type: checksum_type })
      return metadata
    end
    return metadata if checksum_type.nil? || checksum_type == :none

    # :etag means "verify with whatever digest the server hands us"; with
    # no header to hand us one, fall back to the agent's configured
    # digest algorithm, which -- unlike a hardcoded md5 -- is guaranteed
    # usable under FIPS.
    digest_type = checksum_type == :etag ? Puppet[:digest_algorithm].to_sym : checksum_type

    checksum = nil
    client.get(uri, options: { include_system_store: true }) do |response|
      return nil unless response.success?

      checksum = send("#{digest_type}_stream") do |sum|
        response.read_body { |chunk| sum << chunk }
      end
    end

    metadata.verify!(digest_type, checksum)
    metadata
  end
end
