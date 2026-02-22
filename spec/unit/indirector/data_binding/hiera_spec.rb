require 'spec_helper'
require 'puppet/indirector/data_binding/hiera'

describe Puppet::DataBinding::Hiera do
  it "should have documentation" do
    expect(Puppet::DataBinding::Hiera.doc).not_to be_nil
  end

  it "should be registered with the data_binding indirection" do
    indirection = Puppet::Indirector::Indirection.instance(:data_binding)
    expect(Puppet::DataBinding::Hiera.indirection).to equal(indirection)
  end

  it "should have its name set to :hiera" do
    expect(Puppet::DataBinding::Hiera.name).to eq(:hiera)
  end

  it_should_behave_like "Hiera indirection", Puppet::DataBinding::Hiera, my_fixture_dir

  describe "#find", :if => Puppet.features.hiera? do
    let(:data_binder) { described_class.new }
    let(:hiera)       { double('hiera') }

    def request(key, options = {})
      Puppet::Indirector::Request.new(:hiera, :find, key, nil, options)
    end

    before do
      allow(described_class).to receive(:hiera).and_return(hiera)
    end

    it "throws :no_such_key when hiera returns the not_found sentinel" do
      # Returning the default argument signals "not found" to the find method
      allow(hiera).to receive(:lookup) { |_key, default, *_| default }
      expect { data_binder.find(request('missing')) }.to throw_symbol(:no_such_key)
    end
  end

  describe "#convert_merge", :if => Puppet.features.hiera? do
    let(:data_binder) { described_class.new }

    def convert(merge)
      data_binder.send(:convert_merge, merge)
    end

    it "returns nil for nil" do
      expect(convert(nil)).to be_nil
    end

    it "returns nil for 'first'" do
      expect(convert('first')).to be_nil
    end

    it "returns :array for 'unique'" do
      expect(convert('unique')).to eq(:array)
    end

    it "returns native hash behavior for 'hash'" do
      expect(convert('hash')).to eq({ :behavior => :native })
    end

    it "returns deeper hash behavior for 'deep'" do
      expect(convert('deep')).to eq({ :behavior => :deeper })
    end

    it "delegates to the strategy's configuration when given a MergeStrategy" do
      strategy = instance_double(Puppet::Pops::MergeStrategy, :configuration => 'unique')
      expect(convert(strategy)).to eq(:array)
    end

    it "returns deeper hash behavior for a Hash with strategy 'deep'" do
      expect(convert({ 'strategy' => 'deep' })).to eq({ :behavior => :deeper })
    end

    it "forwards extra keys alongside deeper behavior for a Hash with strategy 'deep'" do
      result = convert({ 'strategy' => 'deep', 'knockout_prefix' => '--' })
      expect(result).to eq({ :behavior => :deeper, :knockout_prefix => '--' })
    end

    it "delegates to the string strategy for a Hash with a non-deep strategy" do
      expect(convert({ 'strategy' => 'unique' })).to eq(:array)
    end

    it "raises LookupError for an unrecognized merge value" do
      expect { convert('bogus') }.to raise_error(Puppet::DataBinding::LookupError, /Unrecognized value.*bogus/)
    end
  end
end
