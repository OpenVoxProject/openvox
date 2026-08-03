# frozen_string_literal: true

require_relative '../../../puppet/util/checksums'

# Specify which checksum algorithm to use when checksumming
# files.
Puppet::Type.type(:file).newparam(:checksum) do
  include Puppet::Util::Checksums

  # The default is defined in Puppet.default_digest_algorithm
  desc "The checksum type to use when determining whether to replace a file's contents.

    The default checksum type is sha256.

    Set this to `etag` for `http(s)` sources to prefer a strong `ETag`
    response header (when the server sends one that looks like a real
    digest) over the `Last-Modified` header. See the `source` attribute
    for the full order of preference `http(s)` sources use."

  # The values are defined in Puppet::Util::Checksums.known_checksum_types
  newvalues(:sha256, :sha256lite, :md5, :md5lite, :sha1, :sha1lite, :sha512, :sha384, :sha224, :mtime, :ctime, :none, :etag)

  defaultto do
    Puppet[:digest_algorithm].to_sym
  end

  validate do |value|
    if Puppet::Util::Platform.fips_enabled? && (value == :md5 || value == :md5lite)
      raise ArgumentError, _("MD5 is not supported in FIPS mode")
    end
  end

  def sum(content)
    content = content.is_a?(Puppet::Pops::Types::PBinaryType::Binary) ? content.binary_buffer : content
    type = digest_algorithm
    "{#{type}}" + send(type, content)
  end

  def sum_file(path)
    type = digest_algorithm
    method = type.to_s + "_file"
    "{#{type}}" + send(method, path).to_s
  end

  def sum_stream(&block)
    type = digest_algorithm
    method = type.to_s + "_stream"
    checksum = send(method, &block)
    "{#{type}}#{checksum}"
  end

  private

  # Return the appropriate digest algorithm with fallbacks in case puppet defaults have not
  # been initialized. When the checksum type is :etag, resolve to the actual
  # hash algorithm that the HTTP server's ETag represents.
  def digest_algorithm
    type = value || Puppet[:digest_algorithm].to_sym
    return type unless type == :etag

    source = resource.parameter(:source)
    resolved = source&.metadata&.checksum_type
    if resolved && ![:etag, :mtime, :ctime, :none].include?(resolved)
      return resolved
    end

    # No resolvable ETag-derived type to match (e.g. no source at all).
    # Puppet[:digest_algorithm] is always FIPS-safe, unlike a hardcoded md5.
    Puppet[:digest_algorithm].to_sym
  end
end
