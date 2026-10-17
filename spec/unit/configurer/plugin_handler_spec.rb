require 'spec_helper'
require 'puppet/configurer'
require 'puppet/configurer/plugin_handler'
require 'puppet_spec/files'

describe Puppet::Configurer::PluginHandler do
  include PuppetSpec::Files

  let(:pluginhandler) { Puppet::Configurer::PluginHandler.new() }
  let(:environment)   { Puppet::Node::Environment.create(:myenv, []) }

  before :each do
    # PluginHandler#load_plugin has an extra-strong rescue clause
    # this mock is to make sure that we don't silently ignore errors
    expect(Puppet).not_to receive(:err)

    # Only the pluginmodules downloader checks its source, and these
    # examples are about the other downloaders unless stated otherwise
    allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:source_exists?).and_return(false)
  end

  context "server agent version is 5.3.4" do
    around do |example|
      Puppet.override(server_agent_version: "5.3.4") do
        example.run
      end
    end

    context "when i18n is enabled" do
      before :each do
        Puppet[:disable_i18n] = false
      end

      it "downloads plugins, facts, and locales" do
        times_called = 0
        allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) { times_called += 1 }.and_return([])

        pluginhandler.download_plugins(environment)
        expect(times_called).to eq(3)
      end

      it "returns downloaded plugin, fact, and locale filenames" do
        times_called = 0
        allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) do
          times_called += 1

          if times_called == 1
            %w[/a]
          elsif times_called == 2
            %w[/b]
          else
            %w[/c]
          end
        end

        expect(pluginhandler.download_plugins(environment)).to match_array(%w[/a /b /c])
        expect(times_called).to eq(3)
      end
    end

    context "when i18n is disabled" do
      before :each do
        Puppet[:disable_i18n] = true
      end

      it "downloads plugins, facts, but no locales" do
        times_called = 0
        allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) { times_called += 1 }.and_return([])

        pluginhandler.download_plugins(environment)
        expect(times_called).to eq(2)
      end

      it "returns downloaded plugin, fact, and locale filenames" do
        times_called = 0
        allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) do
          times_called += 1

          if times_called == 1
            %w[/a]
          elsif times_called == 2
            %w[/b]
          else
            %w[/c]
          end
        end

        expect(pluginhandler.download_plugins(environment)).to match_array(%w[/a /b])
        expect(times_called).to eq(2)
      end
    end
  end

  context "when the pluginmodules source exists" do
    before :each do
      Puppet[:disable_i18n] = true
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:source_exists?).and_return(true)
    end

    it "downloads plugins, facts, and module types and functions" do
      sources = []
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) do |downloader|
        sources << downloader.source
        ["/#{downloader.name}"]
      end

      expect(pluginhandler.download_plugins(environment)).to match_array(%w[/pluginfacts /plugin /pluginmodules])
      expect(sources).to eq([Puppet[:pluginfactsource], Puppet[:pluginsource], Puppet[:pluginmodulesource]])
    end

    it "stores module types and functions in pluginmoduledest" do
      expect(Puppet::Configurer::Downloader).to receive(:new).and_call_original.twice
      expect(Puppet::Configurer::Downloader).to receive(:new)
        .with("pluginmodules", Puppet[:pluginmoduledest], Puppet[:pluginmodulesource], Puppet[:pluginsignore], environment)
        .and_return(double('downloader', :source_exists? => true, :evaluate => []))
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate).and_return([])

      pluginhandler.download_plugins(environment)
    end
  end

  context "when the pluginmodules source does not exist" do
    let(:pluginmoduledest) { tmpdir('plugin_modules') }

    before :each do
      Puppet[:disable_i18n] = true
      Puppet[:pluginmoduledest] = pluginmoduledest
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:source_exists?).and_return(false)
    end

    it "does not download module types and functions" do
      names = []
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) do |downloader|
        names << downloader.name
        []
      end

      pluginhandler.download_plugins(environment)
      expect(names).to eq(%w[pluginfacts plugin])
    end

    it "removes previously synced module types and functions" do
      FileUtils.mkdir_p(File.join(pluginmoduledest, 'mymod', 'types'))
      File.write(File.join(pluginmoduledest, 'mymod', 'types', 'port.pp'), 'type Mymod::Port = Integer')
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate).and_return([])

      expect(Puppet).to receive(:info).with(/Removing the module type aliases and functions in #{Regexp.escape(pluginmoduledest)}/)

      expect(pluginhandler.download_plugins(environment)).to eq([File.join(pluginmoduledest, 'mymod')])
      expect(Dir.children(pluginmoduledest)).to be_empty
    end

    it "does nothing when pluginmoduledest does not exist" do
      Puppet[:pluginmoduledest] = File.join(pluginmoduledest, 'missing')
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate).and_return([])

      expect(pluginhandler.download_plugins(environment)).to eq([])
    end
  end

  context "when checking whether the pluginmodules source exists fails" do
    let(:pluginmoduledest) { tmpdir('plugin_modules') }

    before :each do
      Puppet[:disable_i18n] = true
      Puppet[:pluginmoduledest] = pluginmoduledest
      FileUtils.mkdir_p(File.join(pluginmoduledest, 'mymod'))
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:source_exists?).and_raise(Puppet::Error, "Failed to retrieve pluginmodules: boom")
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate).and_return([])
    end

    it "raises the error" do
      expect { pluginhandler.download_plugins(environment) }.to raise_error(Puppet::Error, /boom/)
    end

    it "logs the error and keeps the previously synced copies when ignore_plugin_errors is true" do
      Puppet[:ignore_plugin_errors] = true

      expect(pluginhandler.download_plugins(environment)).to eq([])
      expect(@logs).to include(an_object_having_attributes(level: :err, message: /Could not retrieve pluginmodules: .*boom/))
      expect(Dir.children(pluginmoduledest)).to eq(['mymod'])
    end
  end

  context "server agent version is 5.3.3" do
    around do |example|
      Puppet.override(server_agent_version: "5.3.3") do
        example.run
      end
    end

    it "returns downloaded plugin, fact, but not locale filenames" do
      times_called = 0
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) do
        times_called += 1

        if times_called == 1
          %w[/a]
        else
          %w[/b]
        end
      end

      expect(pluginhandler.download_plugins(environment)).to match_array(%w[/a /b])
      expect(times_called).to eq(2)
    end
  end

  context "blank server agent version" do
    around do |example|
      Puppet.override(server_agent_version: "") do
        example.run
      end
    end

    it "returns downloaded plugin, fact, but not locale filenames" do
      times_called = 0
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) do
        times_called += 1

        if times_called == 1
          %w[/a]
        else
          %w[/b]
        end
      end

      expect(pluginhandler.download_plugins(environment)).to match_array(%w[/a /b])
      expect(times_called).to eq(2)
    end
  end

  context "nil server agent version" do
    it "returns downloaded plugin, fact, but not locale filenames" do
      times_called = 0
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) do
        times_called += 1

        if times_called == 1
          %w[/a]
        else
          %w[/b]
        end
      end

      expect(pluginhandler.download_plugins(environment)).to match_array(%w[/a /b])
      expect(times_called).to eq(2)
    end
  end
end
