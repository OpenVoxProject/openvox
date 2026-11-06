require 'spec_helper'
require 'puppet_spec/compiler'
require 'puppet_spec/files'

Puppet::Type.newtype(:test_deferred) do
  newparam(:name)
  newproperty(:value)
end

describe Puppet::Pops::Evaluator::DeferredResolver do
  include PuppetSpec::Compiler
  include PuppetSpec::Files

  let(:env_dir) do
    dir_containing('testing', 'modules' => {
      'testmod' => { 'functions' => { 'test.pp' => 'function testmod::test($x) { "Got: ${x}" }' } }
    })
  end
  let(:environment) { Puppet::Node::Environment.create(:testing, [File.join(env_dir, 'modules')]) }
  let(:facts) { Puppet::Node::Facts.new('node.example.com') }

  def compile_and_resolve_catalog(code, preprocess = false)
    catalog = compile_to_catalog(code)
    described_class.resolve_and_replace(facts, catalog, environment, preprocess)
    catalog
  end

  it 'resolves deferred values in a catalog' do
    catalog = compile_and_resolve_catalog(<<~END, true)
      notify { "deferred":
        message => Deferred("join", [[1,2,3], ":"])
      }
    END

    expect(catalog.resource(:notify, 'deferred')[:message]).to eq('1:2:3')
  end

  it 'lazily resolves deferred values in a catalog' do
    catalog = compile_and_resolve_catalog(<<~END)
      notify { "deferred":
        message => Deferred("join", [[1,2,3], ":"])
      }
    END

    deferred = catalog.resource(:notify, 'deferred')[:message]
    expect(deferred.resolve).to eq('1:2:3')
  end

  it 'lazily resolves nested deferred values in a catalog' do
    catalog = compile_and_resolve_catalog(<<~END)
      $args = Deferred("inline_epp", ["<%= 'a,b,c' %>"])
      notify { "deferred":
        message => Deferred("split", [$args, ","])
      }
    END

    deferred = catalog.resource(:notify, 'deferred')[:message]
    expect(deferred.resolve).to eq(["a", "b", "c"])
  end

  it 'marks the parameter as sensitive when passed an array containing a Sensitive instance' do
    catalog = compile_and_resolve_catalog(<<~END)
      test_deferred { "deferred":
        value => Deferred('join', [['a', Sensitive('b')], ':'])
      }
    END

    resource = catalog.resource(:test_deferred, 'deferred')
    expect(resource.sensitive_parameters).to eq([:value])
  end

  it 'marks the parameter as sensitive when passed a hash containing a Sensitive key' do
    catalog = compile_and_resolve_catalog(<<~END)
      test_deferred { "deferred":
        value => Deferred('keys', [{Sensitive('key') => 'value'}])
      }
    END

    resource = catalog.resource(:test_deferred, 'deferred')
    expect(resource.sensitive_parameters).to eq([:value])
  end

  it 'marks the parameter as sensitive when passed a hash containing a Sensitive value' do
    catalog = compile_and_resolve_catalog(<<~END)
      test_deferred { "deferred":
        value => Deferred('values', [{key => Sensitive('value')}])
      }
    END

    resource = catalog.resource(:test_deferred, 'deferred')
    expect(resource.sensitive_parameters).to eq([:value])
  end

  it 'marks the parameter as sensitive when passed a nested Deferred containing a Sensitive type' do
    catalog = compile_and_resolve_catalog(<<~END)
      $vars = {'token' => Deferred('new', [Sensitive, "hello"])}
      test_deferred { "deferred":
        value => Deferred('inline_epp', ['<%= $token %>', $vars])
      }
    END

    resource = catalog.resource(:test_deferred, 'deferred')
    expect(resource.sensitive_parameters).to eq([:value])
  end

  it 'resolves deferred values that call Puppet language functions' do
    catalog = compile_and_resolve_catalog(<<~END, true)
      notify { "deferred":
        message => Deferred("testmod::test", ["hello"])
      }
    END

    expect(catalog.resource(:notify, 'deferred')[:message]).to eq('Got: hello')
  end

  context 'on an agent' do
    let(:agent_environment) { Puppet::Node::Environment.remote(:testing) }

    before(:each) do
      Puppet[:libdir] = dir_containing('lib', 'puppet' => {
        'functions' => {
          'synced' => {
            'port.rb' => <<~RUBY
              Puppet::Functions.create_function(:'synced::port') do
                dispatch :port do
                  param 'Synced::Port', :value
                end

                def port(value)
                  value
                end
              end
            RUBY
          }
        }
      })
      Puppet[:pluginmoduledest] = dir_containing('plugin_modules', 'synced' => {
        'types' => { 'port.pp' => 'type Synced::Port = Integer[1, 65535]' },
        'functions' => {
          'double.pp' => <<~PUPPET
            function synced::double(Synced::Port $value) >> Integer {
              synced::port($value) * 2
            }
          PUPPET
        }
      })
    end

    def resolve_on_agent(function, *args)
      catalog = Puppet::Resource::Catalog.new('node.example.com', agent_environment)
      deferred = Puppet::Pops::Types::TypeFactory.deferred.create(function, args)
      catalog.add_resource(Puppet::Resource.new(:notify, 'deferred', :parameters => { :message => deferred }))
      Puppet.override(:loaders => Puppet::Pops::Loaders.new(agent_environment, true)) do
        described_class.resolve_and_replace(facts, catalog, agent_environment, true)
      end
      catalog.resource(:notify, 'deferred')[:message]
    end

    it 'resolves a pluginsynced ruby function that uses a pluginsynced type alias' do
      expect(resolve_on_agent('synced::port', 8140)).to eq(8140)
    end

    it 'enforces a pluginsynced type alias' do
      expect { resolve_on_agent('synced::port', 0) }.to raise_error(ArgumentError, /expects a Synced::Port = Integer\[1, 65535\] value/)
    end

    it 'resolves a pluginsynced Puppet language function' do
      expect(resolve_on_agent('synced::double', 80)).to eq(160)
    end
  end
end
