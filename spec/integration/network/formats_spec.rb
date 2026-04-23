require 'spec_helper'

require 'puppet/network/formats'

describe Puppet::Network::FormatHandler.format(:s) do
  before do
    @format = Puppet::Network::FormatHandler.format(:s)
  end

  it "should support certificates" do
    expect(@format).to be_supported(Puppet::SSL::Certificate)
  end

  it "should not support catalogs" do
    expect(@format).not_to be_supported(Puppet::Resource::Catalog)
  end
end

