require 'spec_helper'
require 'digest'

require 'puppet/indirector/file_metadata'
require 'puppet/indirector/file_metadata/http'

describe Puppet::Indirector::FileMetadata::Http do
  DEFAULT_HEADERS = {
    "Cache-Control" => "private, max-age=0",
    "Connection" => "close",
    "Content-Encoding" => "gzip",
    "Content-Type" => "text/html; charset=ISO-8859-1",
    "Date" => "Fri, 01 May 2020 17:16:00 GMT",
    "Expires" => "-1",
    "Server" => "gws"
  }.freeze

  let(:certname) { 'ziggy' }
  # The model is Puppet:FileServing::Metadata
  let(:model) { described_class.model }
  # The http terminus creates instances of HttpMetadata which subclass Metadata
  let(:metadata) { Puppet::FileServing::HttpMetadata.new(key) }
  let(:key) { "https://example.com/path/to/file" }
  # Digest::MD5.base64digest("") => "1B2M2Y8AsgTpgAmY7PhCfg=="
  let(:content_md5) { {"Content-MD5" => "1B2M2Y8AsgTpgAmY7PhCfg=="} }
  let(:last_modified) { {"Last-Modified" => "Wed, 01 Jan 2020 08:00:00 GMT"} }

  before :each do
    described_class.indirection.terminus_class = :http
  end

  context "when finding" do
    it "returns http file metadata" do
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS)

      result = model.indirection.find(key)
      expect(result.ftype).to eq('file')
      expect(result.path).to eq('/dev/null')
      expect(result.relative_path).to be_nil
      expect(result.destination).to be_nil
      expect(result.checksum).to eq('{none}')
      expect(result.owner).to be_nil
      expect(result.group).to be_nil
      expect(result.mode).to be_nil
    end

    it "reports an md5 checksum if present in the response" do
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS.merge(content_md5))

      result = model.indirection.find(key)
      expect(result.checksum_type).to eq(:md5)
      expect(result.checksum).to eq("{md5}d41d8cd98f00b204e9800998ecf8427e")
    end

    it "reports an mtime checksum if present in the response" do
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS.merge(last_modified))

      result = model.indirection.find(key)
      expect(result.checksum_type).to eq(:mtime)
      expect(result.checksum).to eq("{mtime}2020-01-01 08:00:00 UTC")
    end

    it "prefers md5" do
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS.merge(content_md5).merge(last_modified))

      result = model.indirection.find(key)
      expect(result.checksum_type).to eq(:md5)
      expect(result.checksum).to eq("{md5}d41d8cd98f00b204e9800998ecf8427e")
    end

    it "prefers mtime when explicitly requested" do
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS.merge(content_md5).merge(last_modified))

      result = model.indirection.find(key, checksum_type: :mtime)
      expect(result.checksum_type).to eq(:mtime)
      expect(result.checksum).to eq("{mtime}2020-01-01 08:00:00 UTC")
    end

    it "does not auto-activate ETag without checksum_type => etag" do
      etag_md5 = "f5ffec8d8d16b43d5e9ac6ad4330c445"
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS.merge("ETag" => %("#{etag_md5}")))

      result = model.indirection.find(key)
      expect(result.checksum_type).to eq(:none)
    end

    it "uses ETag as md5 when checksum_type is etag" do
      etag_md5 = "f5ffec8d8d16b43d5e9ac6ad4330c445"
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS.merge("ETag" => %("#{etag_md5}")))

      result = model.indirection.find(key, checksum_type: :etag)
      expect(result.checksum_type).to eq(:md5)
      expect(result.checksum).to eq("{md5}#{etag_md5}")
    end

    it "prefers explicit X-Checksum-Sha256 over ETag when not using etag checksum" do
      sha256 = "a3eda98259c30e1e75039c2123670c18105e1c46efb672e42ca0e4cbe77b002a"
      etag_md5 = "f5ffec8d8d16b43d5e9ac6ad4330c445"
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS.merge(
          "X-Checksum-Sha256" => sha256,
          "ETag" => %("#{etag_md5}")
        ))

      result = model.indirection.find(key)
      expect(result.checksum_type).to eq(:sha256)
      expect(result.checksum).to eq("{sha256}#{sha256}")
    end

    it "ignores weak ETags even with checksum_type => etag, and earns a checksum via GET instead" do
      body = "some file content"
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS.merge(
          "ETag" => 'W/"f5ffec8d8d16b43d5e9ac6ad4330c445"'
        ))
      stub_request(:get, key).to_return(status: 200, body: body)

      result = model.indirection.find(key, checksum_type: :etag)
      expect(result.checksum_type).to eq(Puppet[:digest_algorithm].to_sym)
      expect(result.checksum).to eq("{#{Puppet[:digest_algorithm]}}#{Digest::SHA256.hexdigest(body)}")
    end

    it "leniently parses base64" do
      # Content-MD5 header is missing '==' padding
      stub_request(:head, key)
        .to_return(status: 200, headers: DEFAULT_HEADERS.merge("Content-MD5" => "1B2M2Y8AsgTpgAmY7PhCfg"))

      result = model.indirection.find(key)
      expect(result.checksum_type).to eq(:md5)
      expect(result.checksum).to eq("{md5}d41d8cd98f00b204e9800998ecf8427e")
    end

    it "URL encodes special characters" do
      pending("HTTP terminus doesn't encode the URI before parsing")

      stub_request(:head, %r{/path%20to%20file})

      model.indirection.find('https://example.com/path to file')
    end

    it "sends query parameters" do
      stub_request(:head, key).with(query: {'a' => 'b'})

      model.indirection.find("#{key}?a=b")
    end

    it "returns nil if the content doesn't exist" do
      stub_request(:head, key).to_return(status: 404)

      expect(model.indirection.find(key)).to be_nil
    end

    it "returns nil if fail_on_404" do
      stub_request(:head, key).to_return(status: 404)

      expect(model.indirection.find(key, fail_on_404: true)).to be_nil
    end

    it "returns nil on HTTP 500" do
      stub_request(:head, key).to_return(status: 500)

      # this is kind of strange, but it does allow puppet to try
      # multiple `source => ["URL1", "URL2"]` and use the first
      # one based on sourceselect
      expect(model.indirection.find(key)).to be_nil
    end

    it "accepts all content types" do
      stub_request(:head, key).with(headers: {'Accept' => '*/*'})

      model.indirection.find(key)
    end

    it "sets puppet user-agent" do
      stub_request(:head, key).with(headers: {'User-Agent' => Puppet[:http_user_agent]})

      model.indirection.find(key)
    end

    it "tries to persist the connection" do
      # HTTP/1.1 defaults to persistent connections, so check for
      # the header's absence
      stub_request(:head, key).with do |request|
        expect(request.headers).to_not include('Connection')
      end

      model.indirection.find(key)
    end

    it "follows redirects" do
      new_url = "https://example.com/different/path"
      redirect = { status: 200, headers: { 'Location' => new_url }, body: ""}
      stub_request(:head, key).to_return(redirect)
      stub_request(:head, new_url)

      model.indirection.find(key)
    end

    it "falls back to partial GET if HEAD is not allowed" do
      stub_request(:head, key)
        .to_return(status: 405)
      stub_request(:get, key)
        .to_return(status: 200, headers: {'Range' => 'bytes=0-0'})

      model.indirection.find(key)
    end

    it "falls back to partial GET if HEAD is forbidden" do
      stub_request(:head, key)
        .to_return(status: 403)
      stub_request(:get, key)
        .to_return(status: 200, headers: {'Range' => 'bytes=0-0'})

      model.indirection.find(key)
    end

    it "returns nil if the partial GET fails" do
      stub_request(:head, key)
        .to_return(status: 403)
      stub_request(:get, key)
        .to_return(status: 403)

      expect(model.indirection.find(key)).to be_nil
    end
  end

  context "when no header can provide a checksum" do
    it "earns one via GET when a real digest was requested" do
      body = "some file content"
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS)
      stub_request(:get, key).to_return(status: 200, body: body)

      result = model.indirection.find(key, checksum_type: :sha256)
      expect(result.checksum_type).to eq(:sha256)
      expect(result.checksum).to eq("{sha256}#{Digest::SHA256.hexdigest(body)}")
    end

    it "does not fetch the body when checksum_type is mtime, but warns that changes can never be detected" do
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS)
      # No :get stub: a network call here would fail the example.

      expect(Puppet).to receive(:warning).with(/checksum => mtime the file will never be detected as changed/)
      result = model.indirection.find(key, checksum_type: :mtime)
      expect(result.checksum_type).to eq(:none)
    end

    it "does not fetch the body when checksum_type is ctime, but warns that changes can never be detected" do
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS)

      expect(Puppet).to receive(:warning).with(/checksum => ctime the file will never be detected as changed/)
      result = model.indirection.find(key, checksum_type: :ctime)
      expect(result.checksum_type).to eq(:none)
    end

    it "does not fetch the body or warn when checksum_type is none" do
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS)

      expect(Puppet).not_to receive(:warning)
      result = model.indirection.find(key, checksum_type: :none)
      expect(result.checksum_type).to eq(:none)
    end

    it "does not fetch the body or warn when no checksum_type was requested at all" do
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS)

      expect(Puppet).not_to receive(:warning)
      result = model.indirection.find(key)
      expect(result.checksum_type).to eq(:none)
    end

    it "treats a failed verification GET as not found, rather than as unchanged" do
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS)
      stub_request(:get, key).to_return(status: 500)

      expect(model.indirection.find(key, checksum_type: :sha256)).to be_nil
    end

    it "propagates a network error during the verification GET, rather than treating it as unchanged" do
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS)
      stub_request(:get, key).to_raise(Errno::ECONNREFUSED)

      # Match Puppet's own wrapper text, not the strerror for ECONNREFUSED,
      # which differs between platforms (Windows says "No connection could
      # be made because the target machine actively refused it.").
      expect {
        model.indirection.find(key, checksum_type: :sha256)
      }.to raise_error(Puppet::HTTP::HTTPError, %r{Request to https://example\.com/path/to/file failed})
    end

    it "falls back to Puppet[:digest_algorithm] (not a hardcoded md5) when checksum_type is etag and nothing resolves" do
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS)
      body = "some file content"
      stub_request(:get, key).to_return(status: 200, body: body)

      result = model.indirection.find(key, checksum_type: :etag)
      expect(result.checksum_type).to eq(Puppet[:digest_algorithm].to_sym)
      expect(result.checksum).to eq("{#{Puppet[:digest_algorithm]}}#{Digest::SHA256.hexdigest(body)}")
    end

    it "does not fall back to md5 for checksum_type etag under FIPS" do
      allow(Puppet::Util::Platform).to receive(:fips_enabled?).and_return(true)
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS)
      stub_request(:get, key).to_return(status: 200, body: "some file content")

      result = model.indirection.find(key, checksum_type: :etag)
      expect(result.checksum_type).not_to eq(:md5)
    end

    it "does not double-earn a checksum when a header already provided one" do
      # A real header-derived checksum should short-circuit before any GET,
      # regardless of what was requested.
      stub_request(:head, key).to_return(status: 200, headers: DEFAULT_HEADERS.merge(last_modified))
      # No :get stub: a network call here would fail the example.

      result = model.indirection.find(key, checksum_type: :sha256)
      expect(result.checksum_type).to eq(:mtime)
    end
  end

  context "when searching" do
    it "raises an error" do
      expect {
        model.indirection.search(key)
      }.to raise_error(Puppet::Error, 'cannot lookup multiple files')
    end
  end
end
