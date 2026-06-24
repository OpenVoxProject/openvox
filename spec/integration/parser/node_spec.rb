require 'spec_helper'
require 'puppet_spec/compiler'
require 'matchers/resource'

describe 'node statements' do
  include PuppetSpec::Compiler
  include Matchers::Resource

  context 'nodes' do
    it 'selects a node where the name is just a number' do
      # Future parser doesn't allow a number in this position
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("5"))
      node 5 { notify { 'matched': } }
      MANIFEST

      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'selects the node with a matching name' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("nodename"))
      node noden {}
      node nodename { notify { matched: } }
      node name {}
      MANIFEST

      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'prefers a node with a literal name over one with a regex' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("nodename"))
      node /noden.me/ { notify { ignored: } }
      node nodename { notify { matched: } }
      MANIFEST

      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'selects a node where one of the names matches' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("nodename"))
      node different, nodename, other { notify { matched: } }
      MANIFEST

      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'arbitrarily selects one of the matching nodes' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("nodename"))
      node /not/ { notify { 'is not matched': } }
      node /name.*/ { notify { 'could be matched': } }
      node /na.e/ { notify { 'could also be matched': } }
      MANIFEST

      expect([catalog.resource('Notify[could be matched]'), catalog.resource('Notify[could also be matched]')].compact).to_not be_empty
    end

    it 'selects a node where one of the names matches with a mixture of literals and regex' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("nodename"))
      node different, /name/, other { notify { matched: } }
      MANIFEST

      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'that have regex names should not collide with matching class names' do
        catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("foo"))
        class foo {
          $bar = 'one'
        }

        node /foo/ {
          $bar = 'two'
          include foo
          notify{"${::foo::bar}":}
        }
        MANIFEST
        expect(catalog).to have_resource('Notify[one]')
    end

    it 'does not raise an error with regex and non-regex node names are the same' do
      expect do
        compile_to_catalog(<<-MANIFEST)
        node /a.*(c)?/ { }
        node 'a.c' { }
        MANIFEST
      end.not_to raise_error
    end

    it 'does not raise an error with 2 regex node names are the same due to lookaround pattern' do
      expect do
        compile_to_catalog(<<-MANIFEST, Puppet::Node.new("async"))
        node /(?<!a)sync/ { }
        node /async/ { }
        MANIFEST
      end.not_to raise_error
    end

    it 'errors when two nodes with regexes collide after some regex syntax is removed' do
      expect do
        compile_to_catalog(<<-MANIFEST)
        node /a.*(c)?/ { }
        node /a.*c/ { }
        MANIFEST
      end.to raise_error(Puppet::Error, /Node '__node_regexp__a.c' is already defined/)
    end

    # Regression test for https://github.com/OpenVoxProject/openvox/issues/14
    # A regex with non-capturing group syntax (?:...) or other lookaround constructs
    # caused uppercase characters to appear in the synthetic node key, which is stored
    # in the TypeCollection hash.  Lookups always downcase the key via munge_name(), so
    # the node could never be found again, producing "Cannot find definition Node".
    it 'matches a node whose regex contains a non-capturing group' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("thing-foo-42"))
      node /^thing-(foo|bar)(?:-test)?-(\\d+)$/ { notify { matched: } }
      node default                              { notify { unmatched: } }
      MANIFEST

      expect(catalog).not_to have_resource('Notify[unmatched]')
      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'matches a node whose regex contains a non-capturing group for the optional suffix' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("thing-bar-test-7"))
      node /^thing-(foo|bar)(?:-test)?-(\\d+)$/ { notify { matched: } }
      node default                              { notify { unmatched: } }
      MANIFEST

      expect(catalog).not_to have_resource('Notify[unmatched]')
      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'does not match a node when the non-capturing-group regex prefix does not match' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("thing-baz-7"))
      node /^thing-(foo|bar)(?:-test)?-(\\d+)$/ { notify { matched: } }
      node default                              { notify { unmatched: } }
      MANIFEST

      expect(catalog).not_to have_resource('Notify[matched]')
      expect(catalog).to have_resource('Notify[unmatched]')
    end

    it 'matches a node whose regex contains a negative lookahead' do
      # /^(db01)\.(?!hosts).*$/ matches db01.<anything-except-hosts...>
      # e.g. db01.example.com matches, db01.hosts.example.com does not
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("db01.example.com"))
      node /^(db01)\.(?!hosts).*$/ { notify { matched: } }
      node default                 { notify { unmatched: } }
      MANIFEST

      expect(catalog).not_to have_resource('Notify[unmatched]')
      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'does not match a node excluded by a negative lookahead' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("db01.hosts.example.com"))
      node /^(db01)\.(?!hosts).*$/ { notify { matched: } }
      node default                 { notify { unmatched: } }
      MANIFEST

      expect(catalog).not_to have_resource('Notify[matched]')
      expect(catalog).to     have_resource('Notify[unmatched]')
    end

    it 'provides captures from the regex in the node body' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("nodename"))
      node /(.*)/ { notify { "$1": } }
      MANIFEST
      expect(catalog).to have_resource('Notify[nodename]')
    end

    it 'selects the node with the matching regex' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("nodename"))
      node /node.*/ { notify { matched: } }
      MANIFEST

      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'selects a node that is a literal string' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("node.name"))
      node 'node.name' { notify { matched: } }
      MANIFEST

      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'does not treat regex symbols as a regex inside a string literal' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("nodexname"))
      node 'node.name' { notify { 'not matched': } }
      node 'nodexname' { notify { 'matched': } }
      MANIFEST

      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'errors when two nodes have the same name' do
      expect do
        compile_to_catalog(<<-MANIFEST)
        node name { }
        node 'name' { }
        MANIFEST
      end.to raise_error(Puppet::Error, /Node 'name' is already defined/)
    end

    it 'is unable to parse a name that is an invalid number' do
      expect do
        compile_to_catalog('node 5name {} ')
      end.to raise_error(Puppet::Error, /Illegal number '5name'/)
    end

    it 'parses a node name that is dotted numbers' do
      catalog = compile_to_catalog(<<-MANIFEST, Puppet::Node.new("1.2.3.4"))
        node 1.2.3.4 { notify { matched: } }
      MANIFEST

      expect(catalog).to have_resource('Notify[matched]')
    end

    it 'raises error for node inheritance' do
      expect do
        compile_to_catalog(<<-MANIFEST, Puppet::Node.new("nodename"))
        node default {}
          node nodename inherits default {  }
        MANIFEST
      end.to raise_error(/Node inheritance is not supported in Puppet >= 4\.0\.0/)
    end

  end

end
