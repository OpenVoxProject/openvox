require 'spec_helper'
require 'puppet/network/http_pool'

class Puppet::Network::HttpPool::FooClient
  def initialize(host, port, options = {})
    @host = host
    @port = port
  end
  attr_reader :host, :port
end

describe Puppet::Network::HttpPool do
  include PuppetSpec::Files

  describe "when registering an http client class" do
    let(:http_impl) { Puppet::Network::HttpPool::FooClient }

    around :each do |example|
      orig_class = Puppet::Network::HttpPool.http_client_class
      begin
        example.run
      ensure
        Puppet::Network::HttpPool.http_client_class = orig_class
      end
    end

    it "uses the default http client" do
      expect(Puppet.runtime[:http]).to be_an_instance_of(Puppet::HTTP::Client)
    end

    it "switches to the external client implementation" do
      Puppet::Network::HttpPool.http_client_class = http_impl

      expect(Puppet.runtime[:http]).to be_an_instance_of(Puppet::HTTP::ExternalClient)
    end

    it "always uses an explicitly registered http implementation" do
      Puppet::Network::HttpPool.http_client_class = http_impl

      new_impl = double('new_http_impl')
      Puppet.initialize_settings([], true, true, http: new_impl)

      expect(Puppet.runtime[:http]).to eq(new_impl)
    end
  end
end
