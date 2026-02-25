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
end
