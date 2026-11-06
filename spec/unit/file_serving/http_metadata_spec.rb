require 'spec_helper'
require 'puppet/file_serving/http_metadata'
require 'matchers/json'
require 'net/http'
require 'digest'

describe Puppet::FileServing::HttpMetadata do
  let(:foobar) { File.expand_path('/foo/bar') }

  it "should be a subclass of Metadata" do
    expect( described_class.superclass ).to be Puppet::FileServing::Metadata
  end

  describe "when initializing" do
    let(:http_response) { Net::HTTPOK.new(1.0, '200', 'OK') }

    it "can be instantiated from a HTTP response object" do
      expect( described_class.new(http_response) ).to_not be_nil
    end

    it "represents a plain file" do
      expect( described_class.new(http_response).ftype ).to eq 'file'
    end

    it "carries no information on owner, group and mode" do
      metadata = described_class.new(http_response)
      expect( metadata.owner ).to be_nil
      expect( metadata.group ).to be_nil
      expect( metadata.mode ).to be_nil
    end

    it "skips md5 checksum type in collect on FIPS enabled platforms" do
      allow(Puppet::Util::Platform).to receive(:fips_enabled?).and_return(true)
      http_response['X-Checksum-Md5'] = 'c58989e9740a748de4f5054286faf99b'
      metadata = described_class.new(http_response)
      metadata.collect
      expect( metadata.checksum ).to be_nil
    end

    context "with no Last-Modified or Content-MD5 header from the server" do
      it "should not report a checksum" do
        metadata = described_class.new(http_response)
        metadata.collect
        expect( metadata.checksum ).to be_nil
      end
    end

    context "with a Last-Modified header from the server" do
      let(:time) { Time.now.utc }

      it "should use :mtime as the checksum type, based on Last-Modified" do
        # HTTP uses "GMT" not "UTC"
        http_response.add_field('last-modified', time.strftime("%a, %d %b %Y %T GMT"))
        metadata = described_class.new(http_response)
        metadata.collect
        expect( metadata.checksum_type ).to eq :mtime
        expect( metadata.checksum ).to eq "{mtime}#{time.to_time.utc}"
      end
    end

    context "with a Content-MD5 header being received" do
      let(:input) { Time.now.to_s }
      let(:base64) { Digest::MD5.new.base64digest input }
      let(:hex) { Digest::MD5.new.hexdigest input }

      it "should use the md5 checksum" do
        http_response.add_field('content-md5', base64)
        metadata = described_class.new(http_response)
        metadata.collect
        expect( metadata.checksum_type ).to eq :md5
        expect( metadata.checksum ).to eq "{md5}#{hex}"
      end
    end

    context "with X-Checksum-Md5" do
      let(:md5) { "c58989e9740a748de4f5054286faf99b" }

      it "should use the md5 checksum" do
        http_response.add_field('X-Checksum-Md5', md5)
        metadata = described_class.new(http_response)
        metadata.collect
        expect( metadata.checksum_type ).to eq :md5
        expect( metadata.checksum ).to eq "{md5}#{md5}"
      end
    end

    context "with X-Checksum-Sha1" do
      let(:sha1) { "01e4d15746f4274b84d740a93e04b9fd2882e3ea" }

      it "should use the SHA1 checksum" do
        http_response.add_field('X-Checksum-Sha1', sha1)
        metadata = described_class.new(http_response)
        metadata.collect
        expect( metadata.checksum_type ).to eq :sha1
        expect( metadata.checksum ).to eq "{sha1}#{sha1}"
      end
    end

    context "with X-Checksum-Sha256" do
      let(:sha256) { "a3eda98259c30e1e75039c2123670c18105e1c46efb672e42ca0e4cbe77b002a" }

      it "should use the SHA256 checksum" do
        http_response.add_field('X-Checksum-Sha256', sha256)
        metadata = described_class.new(http_response)
        metadata.collect
        expect( metadata.checksum_type ).to eq :sha256
        expect( metadata.checksum ).to eq "{sha256}#{sha256}"
      end
    end

    context "with an ETag header" do
      context "without checksum => etag" do
        let(:md5) { "f5ffec8d8d16b43d5e9ac6ad4330c445" }

        it "does not auto-activate ETag" do
          http_response.add_field('ETag', %("#{md5}"))
          metadata = described_class.new(http_response)
          metadata.collect
          expect( metadata.checksum ).to be_nil
        end
      end

      context "with checksum_type => etag" do
        context "containing an MD5 hash" do
          let(:md5) { "f5ffec8d8d16b43d5e9ac6ad4330c445" }

          it "resolves to md5" do
            http_response.add_field('ETag', %("#{md5}"))
            metadata = described_class.new(http_response)
            metadata.checksum_type = :etag
            metadata.collect
            expect( metadata.checksum_type ).to eq :md5
            expect( metadata.checksum ).to eq "{md5}#{md5}"
          end

          it "normalizes uppercase hex to lowercase" do
            http_response.add_field('ETag', %("#{md5.upcase}"))
            metadata = described_class.new(http_response)
            metadata.checksum_type = :etag
            metadata.collect
            expect( metadata.checksum ).to eq "{md5}#{md5}"
          end
        end

        context "containing a SHA1 hash" do
          let(:sha1) { "01e4d15746f4274b84d740a93e04b9fd2882e3ea" }

          it "resolves to sha1" do
            http_response.add_field('ETag', %("#{sha1}"))
            metadata = described_class.new(http_response)
            metadata.checksum_type = :etag
            metadata.collect
            expect( metadata.checksum_type ).to eq :sha1
            expect( metadata.checksum ).to eq "{sha1}#{sha1}"
          end
        end

        context "containing a SHA256 hash" do
          let(:sha256) { "a3eda98259c30e1e75039c2123670c18105e1c46efb672e42ca0e4cbe77b002a" }

          it "resolves to sha256" do
            http_response.add_field('ETag', %("#{sha256}"))
            metadata = described_class.new(http_response)
            metadata.checksum_type = :etag
            metadata.collect
            expect( metadata.checksum_type ).to eq :sha256
            expect( metadata.checksum ).to eq "{sha256}#{sha256}"
          end
        end

        context "that is a weak ETag" do
          it "ignores the ETag" do
            http_response.add_field('ETag', 'W/"f5ffec8d8d16b43d5e9ac6ad4330c445"')
            metadata = described_class.new(http_response)
            metadata.checksum_type = :etag
            metadata.collect
            expect( metadata.checksum ).to be_nil
          end
        end

        context "that is not a recognizable hash" do
          it "ignores the ETag" do
            http_response.add_field('ETag', '"5e8c5-27a-3e8b8840"')
            metadata = described_class.new(http_response)
            metadata.checksum_type = :etag
            metadata.collect
            expect( metadata.checksum ).to be_nil
          end
        end

        context "when explicit checksum headers are also present" do
          let(:explicit_md5) { "c58989e9740a748de4f5054286faf99b" }
          let(:etag_md5) { "f5ffec8d8d16b43d5e9ac6ad4330c445" }

          it "prefers the ETag over X-Checksum-Md5" do
            http_response.add_field('X-Checksum-Md5', explicit_md5)
            http_response.add_field('ETag', %("#{etag_md5}"))
            metadata = described_class.new(http_response)
            metadata.checksum_type = :etag
            metadata.collect
            expect( metadata.checksum_type ).to eq :md5
            expect( metadata.checksum ).to eq "{md5}#{etag_md5}"
          end
        end

        context "with ETag and Last-Modified" do
          let(:md5) { "f5ffec8d8d16b43d5e9ac6ad4330c445" }
          let(:time) { Time.now.utc }

          it "prefers ETag-derived md5 over mtime" do
            http_response.add_field('ETag', %("#{md5}"))
            http_response.add_field('last-modified', time.strftime("%a, %d %b %Y %T GMT"))
            metadata = described_class.new(http_response)
            metadata.checksum_type = :etag
            metadata.collect
            expect( metadata.checksum_type ).to eq :md5
            expect( metadata.checksum ).to eq "{md5}#{md5}"
          end
        end

        it "skips ETag-derived md5 on FIPS platforms" do
          allow(Puppet::Util::Platform).to receive(:fips_enabled?).and_return(true)
          http_response.add_field('ETag', '"f5ffec8d8d16b43d5e9ac6ad4330c445"')
          metadata = described_class.new(http_response)
          metadata.checksum_type = :etag
          metadata.collect
          expect( metadata.checksum ).to be_nil
        end

        it "falls back to other checksums when no ETag is present" do
          time = Time.now.utc
          http_response.add_field('last-modified', time.strftime("%a, %d %b %Y %T GMT"))
          metadata = described_class.new(http_response)
          metadata.checksum_type = :etag
          metadata.collect
          expect( metadata.checksum_type ).to eq :mtime
          expect( metadata.checksum ).to eq "{mtime}#{time.to_time.utc}"
        end
      end
    end
  end

  describe "when checksumming the response body" do
    let(:http_response) { Net::HTTPOK.new(1.0, '200', 'OK') }
    let(:body_response) { double('response') }
    let(:content) { "test content" }

    before :each do
      allow(body_response).to receive(:read_body).and_yield(content[0, 4]).and_yield(content[4..-1])
    end

    it "uses Puppet[:digest_algorithm] by default" do
      Puppet[:digest_algorithm] = 'sha384'
      metadata = described_class.new(http_response)
      metadata.collect_from_body(body_response)
      expect( metadata.checksum_type ).to eq :sha384
      expect( metadata.checksum ).to eq "{sha384}#{Digest::SHA384.hexdigest(content)}"
    end

    it "uses the requested checksum type when it is a content digest" do
      metadata = described_class.new(http_response)
      metadata.collect_from_body(body_response, :sha512)
      expect( metadata.checksum_type ).to eq :sha512
      expect( metadata.checksum ).to eq "{sha512}#{Digest::SHA512.hexdigest(content)}"
    end

    [:mtime, :etag, :sha256lite].each do |type|
      it "uses Puppet[:digest_algorithm] when #{type} is requested" do
        Puppet[:digest_algorithm] = 'sha384'
        metadata = described_class.new(http_response)
        metadata.collect_from_body(body_response, type)
        expect( metadata.checksum_type ).to eq :sha384
        expect( metadata.checksum ).to eq "{sha384}#{Digest::SHA384.hexdigest(content)}"
      end
    end
  end
end
