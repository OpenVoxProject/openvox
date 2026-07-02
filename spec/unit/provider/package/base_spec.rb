require 'spec_helper'
require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:test_base_provider, parent: Puppet::Provider::Package) do
  def query; end
end

describe Puppet::Provider::Package do
  let(:provider) { Puppet::Type.type(:package).provider(:test_base_provider).new }

  it 'returns absent for uninstalled packages when not purgeable' do
    expect(provider.properties[:ensure]).to eq(:absent)
  end

  it 'returns purged for uninstalled packages when purgeable' do
    expect(provider.class).to receive(:feature?).with(:purgeable).and_return(true)
    expect(provider.properties[:ensure]).to eq(:purged)
  end

  describe '#package_environment' do
    let(:resource) do
      Puppet::Type.type(:package).new(:name => 'test-package', :provider => :test_base_provider)
    end
    let(:provider) { resource.provider }

    it 'returns an empty hash when no environment is set' do
      expect(provider.package_environment).to eq({})
    end

    it 'parses multiple environment variables' do
      resource[:environment] = ['FOO=bar', 'BAZ=quux']
      expect(provider.package_environment).to eq({ 'FOO' => 'bar', 'BAZ' => 'quux' })
    end

    it 'parses values with special characters' do
      resource[:environment] = ['OPENSEARCH_INITIAL_ADMIN_PASSWORD=myStrongP@ss!']
      expect(provider.package_environment).to eq({ 'OPENSEARCH_INITIAL_ADMIN_PASSWORD' => 'myStrongP@ss!' })
    end

    it 'accepts empty values' do
      resource[:environment] = ['FOO=']
      expect(provider.package_environment['FOO']).to eq('')
    end

    it 'accepts a single string value' do
      resource[:environment] = 'FOO=bar'
      expect(provider.package_environment).to eq({ 'FOO' => 'bar' })
    end

    it 'warns on duplicate keys and keeps the last value' do
      resource[:environment] = ['FOO=bar', 'FOO=baz']
      expect(provider).to receive(:warning).with(/Overriding environment setting 'FOO'/)
      expect(provider.package_environment['FOO']).to eq('baz')
    end
  end

  describe '#execute' do
    let(:resource) do
      Puppet::Type.type(:package).new(:name => 'test-package', :provider => :test_base_provider)
    end
    let(:provider) { resource.provider }

    it 'injects custom_environment when environment is set' do
      resource[:environment] = ['FOO=bar']
      expect(Puppet::Util::Execution).to receive(:execute) do |cmd, opts|
        expect(opts[:custom_environment]).to eq({ 'FOO' => 'bar' })
      end
      provider.execute(['echo', 'test'])
    end

    it 'merges with existing custom_environment' do
      resource[:environment] = ['FOO=bar']
      expect(Puppet::Util::Execution).to receive(:execute) do |cmd, opts|
        expect(opts[:custom_environment]).to eq({ 'EXISTING' => 'value', 'FOO' => 'bar' })
      end
      provider.execute(['echo', 'test'], { :custom_environment => { 'EXISTING' => 'value' } })
    end

    it 'passes through unchanged when no environment is set' do
      expect(Puppet::Util::Execution).to receive(:execute).with(['echo', 'test'])
      provider.execute(['echo', 'test'])
    end
  end

  describe '#with_environment' do
    let(:resource) do
      Puppet::Type.type(:package).new(:name => 'test-package', :provider => :test_base_provider)
    end
    let(:provider) { resource.provider }

    it 'is a no-op when no environment is set' do
      original_env = ENV.to_hash
      provider.with_environment do
        expect(ENV.to_hash).to eq(original_env)
      end
    end

    it 'sets environment variables for the duration of the block' do
      resource[:environment] = ['TEST_PKG_ENV=hello']
      provider.with_environment do
        expect(ENV['TEST_PKG_ENV']).to eq('hello')
      end
      expect(ENV['TEST_PKG_ENV']).to be_nil
    end

    it 'restores overridden variables after the block' do
      ENV['TEST_PKG_EXISTING'] = 'original'
      resource[:environment] = ['TEST_PKG_EXISTING=overridden']
      provider.with_environment do
        expect(ENV['TEST_PKG_EXISTING']).to eq('overridden')
      end
      expect(ENV['TEST_PKG_EXISTING']).to eq('original')
      ENV.delete('TEST_PKG_EXISTING')
    end

    it 'restores environment on exception' do
      resource[:environment] = ['TEST_PKG_ENV=hello']
      expect {
        provider.with_environment { raise RuntimeError }
      }.to raise_error(RuntimeError)
      expect(ENV['TEST_PKG_ENV']).to be_nil
    end
  end
end
