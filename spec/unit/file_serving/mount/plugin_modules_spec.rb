require 'spec_helper'
require 'puppet_spec/files'
require 'puppet/file_serving/mount/plugin_modules'
require 'puppet/indirector/file_metadata/file_server'
require 'puppet/indirector/file_content/file_server'

describe Puppet::FileServing::Mount::PluginModules do
  include PuppetSpec::Files

  let(:mount) { described_class.new("pluginmodules") }

  let(:first_modulepath) do
    dir_containing('first', {
      'one' => {
        'lib' => { 'puppet' => { 'functions' => { 'one.rb' => '' } } },
        'manifests' => { 'init.pp' => 'class one {}' },
        'templates' => { 'secret.epp' => 'secret' },
        'types' => {
          'port.pp' => 'type One::Port = Integer',
          'nested' => { 'name.pp' => 'type One::Nested::Name = String' },
        },
        'functions' => { 'greet.pp' => 'function one::greet() { "hi" }' },
      },
      'shadowed' => {
        'types' => { 'first.pp' => 'type Shadowed::First = String' },
      },
      'nothing' => {
        'manifests' => { 'init.pp' => 'class nothing {}' },
      },
    })
  end

  let(:second_modulepath) do
    dir_containing('second', {
      'two' => {
        'functions' => { 'add.pp' => 'function two::add($a, $b) { $a + $b }' },
      },
      'shadowed' => {
        'types' => { 'second.pp' => 'type Shadowed::Second = String' },
      },
    })
  end

  let(:environment) { Puppet::Node::Environment.create(:testing, [first_modulepath, second_modulepath]) }
  let(:options) { { :recurse => true } }
  let(:request) { double('request', :environment => environment, :options => options) }

  before(:each) do
    Puppet::FileServing::Configuration.instance_variable_set(:@configuration, nil)
  end

  def search(key = "pluginmodules")
    Puppet::FileServing::Metadata.indirection.search(key, :environment => environment, :recurse => true)
  end

  def relative_paths(result)
    result.map(&:relative_path).sort
  end

  context "when searching" do
    it "serves the types and functions of each module under the module's name" do
      expect(relative_paths(search)).to eq(%w[
        .
        one
        one/functions
        one/functions/greet.pp
        one/types
        one/types/nested
        one/types/nested/name.pp
        one/types/port.pp
        shadowed
        shadowed/types
        shadowed/types/first.pp
        two
        two/functions
        two/functions/add.pp
      ])
    end

    it "reports the real path of each file" do
      metadata = search.find { |m| m.relative_path == 'two/functions/add.pp' }
      expect(metadata.full_path).to eq(File.join(second_modulepath, 'two', 'functions', 'add.pp'))
      expect(metadata.ftype).to eq('file')
      expect(metadata.checksum).to match(/\A\{sha256\}/)
    end

    it "only serves a module that is shadowed by an earlier module in the modulepath from the earlier module" do
      expect(relative_paths(search)).not_to include('shadowed/types/second.pp')
    end

    it "honors the ignore option" do
      result = Puppet::FileServing::Metadata.indirection.search("pluginmodules", :environment => environment, :recurse => true, :ignore => ['nested'])
      expect(relative_paths(result)).not_to include('one/types/nested', 'one/types/nested/name.pp')
      expect(relative_paths(result)).to include('one/types/port.pp')
    end

    it "serves only the root directory when there are no modules with types or functions" do
      environment = Puppet::Node::Environment.create(:testing, [dir_containing('empty', 'nothing' => { 'manifests' => {} })])
      result = Puppet::FileServing::Metadata.indirection.search("pluginmodules", :environment => environment, :recurse => true)
      expect(relative_paths(result)).to eq(['.'])
    end

    it "serves only the root directory when serve_pluginmodules is false" do
      Puppet[:serve_pluginmodules] = false
      expect(relative_paths(search)).to eq(['.'])
    end

    it "searches a single module when given a relative path" do
      expect(relative_paths(search("pluginmodules/one/types"))).to eq(%w[. nested nested/name.pp port.pp])
    end
  end

  context "when finding" do
    it "returns a directory for the root of the mount" do
      expect(mount.find(nil, request)).to eq(first_modulepath)
    end

    it "returns the codedir as the root of the mount when no modulepath directory exists" do
      environment = Puppet::Node::Environment.create(:testing, [tmpfile('missing')])
      request = double('request', :environment => environment, :options => options)
      expect(mount.find(nil, request)).to eq(Puppet[:codedir])
    end

    it "returns the path of a type alias" do
      expect(mount.find('one/types/nested/name.pp', request)).to eq(File.join(first_modulepath, 'one', 'types', 'nested', 'name.pp'))
    end

    it "returns the path of a function" do
      expect(mount.find('two/functions/add.pp', request)).to eq(File.join(second_modulepath, 'two', 'functions', 'add.pp'))
    end

    it "returns the module directory for a module with types or functions" do
      expect(mount.find('one', request)).to eq(File.join(first_modulepath, 'one'))
    end

    it "does not return a module without types or functions" do
      expect(mount.find('nothing', request)).to be_nil
    end

    it "does not return files outside of the types and functions directories" do
      expect(mount.find('one/templates/secret.epp', request)).to be_nil
      expect(mount.find('one/manifests/init.pp', request)).to be_nil
      expect(mount.find('one/lib/puppet/functions/one.rb', request)).to be_nil
    end

    it "does not return files from a shadowed module" do
      expect(mount.find('shadowed/types/second.pp', request)).to be_nil
    end

    it "returns nil for a module that does not exist" do
      expect(mount.find('missing/types/x.pp', request)).to be_nil
    end

    it "returns nil when serve_pluginmodules is false" do
      Puppet[:serve_pluginmodules] = false
      expect(mount.find('one/types/port.pp', request)).to be_nil
    end

    it "serves file content through the file server" do
      content = Puppet::FileServing::Content.indirection.find("pluginmodules/one/types/port.pp", :environment => environment)
      expect(content.content).to eq('type One::Port = Integer')
    end
  end

  context "when synced by pluginsync" do
    require 'puppet/configurer/downloader'

    let(:dest) { tmpdir('plugin_modules') }

    def sync
      Puppet[:default_file_terminus] = :file_server
      Puppet::Configurer::Downloader.new("pluginmodules", dest, "puppet:///pluginmodules", Puppet[:pluginsignore], environment).evaluate
    end

    def synced_files
      Dir.glob('**/*', base: dest).sort
    end

    it "copies each module's types and functions into a directory named after the module" do
      sync

      expect(synced_files).to eq(%w[
        one
        one/functions
        one/functions/greet.pp
        one/types
        one/types/nested
        one/types/nested/name.pp
        one/types/port.pp
        shadowed
        shadowed/types
        shadowed/types/first.pp
        two
        two/functions
        two/functions/add.pp
      ])
      expect(File.read(File.join(dest, 'two', 'functions', 'add.pp'))).to eq('function two::add($a, $b) { $a + $b }')
    end

    it "removes modules that are no longer served" do
      sync
      FileUtils.rm_rf(File.join(second_modulepath, 'two'))

      sync
      expect(synced_files).not_to include('two')
    end

    it "removes everything when serve_pluginmodules is false" do
      sync
      Puppet[:serve_pluginmodules] = false

      sync
      expect(synced_files).to be_empty
    end
  end
end
