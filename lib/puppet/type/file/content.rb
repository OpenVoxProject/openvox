# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'tempfile'

require_relative '../../../puppet/util/checksums'
require_relative '../../../puppet/type/file/data_sync'

module Puppet
  Puppet::Type.type(:file).newproperty(:content) do
    include Puppet::Util::Checksums
    include Puppet::DataSync

    attr_reader :actual_content

    desc <<-'EOT'
      The desired contents of a file, as a string. This attribute is mutually
      exclusive with `source` and `target`.

      Newlines and tabs can be specified in double-quoted strings using
      standard escaped syntax --- \n for a newline, and \t for a tab.

      With very small files, you can construct content strings directly in
      the manifest...

          define resolve($nameserver1, $nameserver2, $domain, $search) {
              $str = "search ${search}
                  domain ${domain}
                  nameserver ${nameserver1}
                  nameserver ${nameserver2}
                  "

              file { '/etc/resolv.conf':
                content => $str,
              }
          }

      ...but for larger files, this attribute is more useful when combined with the
      [template](https://docs.openvoxproject.org/openvox/latest/function.html#template)
      or [file](https://docs.openvoxproject.org/openvox/latest/function.html#file)
      function.
    EOT

    # Store a checksum as the value, rather than the actual content.
    # Simplifies everything.
    munge do |value|
      if value == :absent
        value
      elsif value.is_a?(String) && checksum?(value) && (@actual_content || resource.parameter(:source))
        # The actual content is already known, either because it was
        # previously set or because it comes from a source, and the value is
        # its checksum.
        value
      else
        # The value is the desired file content, even if it happens to look
        # like a checksum.
        @actual_content = value.is_a?(Puppet::Pops::Types::PBinaryType::Binary) ? value.binary_buffer : value
        resource.parameter(:checksum).sum(@actual_content)
      end
    end

    # Checksums need to invert how changes are printed.
    def change_to_s(currentvalue, newvalue)
      # Our "new" checksum value is provided by the source.
      source = resource.parameter(:source)
      tmp = source.checksum if source
      if tmp
        newvalue = tmp
      end
      if currentvalue == :absent
        "defined content as '#{newvalue}'"
      elsif newvalue == :absent
        "undefined content from '#{currentvalue}'"
      else
        "content changed '#{currentvalue}' to '#{newvalue}'"
      end
    end

    def length
      (actual_content and actual_content.length) || 0
    end

    def content
      should
    end

    # Override this method to provide diffs if asked for.
    # Also, fix #872: when content is used, and replace is true, the file
    # should be insync when it exists
    def insync?(is)
      if resource[:source] && resource[:checksum_value]
        # Asserts that nothing has changed since validate ran.
        devfail "content property should not exist if source and checksum_value are specified"
      end

      contents_prop = resource.parameter(:source) || self
      checksum_insync?(contents_prop, is, !resource[:content].nil?) { |inner| super(inner) }
    end

    def property_matches?(current, desired)
      # If checksum_value is specified, it overrides comparing the content field.
      checksum_type = resource.parameter(:checksum).value
      checksum_value = resource.parameter(:checksum_value)
      if checksum_value
        desired = "{#{checksum_type}}#{checksum_value.value}"
      end

      # The inherited equality is always accepted, so use it if valid.
      return true if super(current, desired)

      date_matches?(checksum_type, current, desired)
    end

    def retrieve
      retrieve_checksum(resource)
    end

    # Make sure we're also managing the checksum property.
    def should=(value)
      # treat the value as a bytestring
      value = value.b if value.is_a?(String)
      @resource.newattr(:checksum) unless @resource.parameter(:checksum)
      super
    end

    # Just write our content out to disk.
    def sync
      contents_sync(resource.parameter(:source) || self)
    end

    def write(file)
      resource.parameter(:checksum).sum_stream { |sum|
        each_chunk_from { |chunk|
          sum << chunk
          file.print chunk
        }
      }
    end

    private

    # actual_content is only nil when the munged value is a checksum of
    # content that comes from a source
    def each_chunk_from
      if actual_content.is_a?(String)
        yield actual_content
      elsif actual_content.nil?
        yield ''
      end
    end
  end
end
