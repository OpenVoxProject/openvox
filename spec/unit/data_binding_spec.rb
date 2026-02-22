require 'spec_helper'
require 'puppet/data_binding'

describe Puppet::DataBinding do
  describe "when indirecting" do
    it "should use the 'hiera' data_binding terminus" do
      expect(Puppet::DataBinding.indirection.terminus_class).to eq(:hiera)
    end
  end
end
