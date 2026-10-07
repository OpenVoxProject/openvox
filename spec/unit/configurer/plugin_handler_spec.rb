require 'spec_helper'
require 'puppet/configurer'
require 'puppet/configurer/plugin_handler'

describe Puppet::Configurer::PluginHandler do
  let(:pluginhandler) { Puppet::Configurer::PluginHandler.new() }
  let(:environment)   { Puppet::Node::Environment.create(:myenv, []) }

  before :each do
    # PluginHandler#load_plugin has an extra-strong rescue clause
    # this mock is to make sure that we don't silently ignore errors
    expect(Puppet).not_to receive(:err)
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

  context "when the server supports the pluginmodules mount" do
    before :each do
      Puppet[:disable_i18n] = true
      allow_any_instance_of(Puppet::HTTP::Session).to receive(:supports?).and_return(false)
      allow_any_instance_of(Puppet::HTTP::Session).to receive(:supports?).with(:puppet, 'pluginmodules').and_return(true)
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
        .and_return(double('downloader', :evaluate => []))
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate).and_return([])

      pluginhandler.download_plugins(environment)
    end
  end

  context "when the server does not support the pluginmodules mount" do
    it "does not download module types and functions" do
      Puppet[:disable_i18n] = true
      names = []
      allow_any_instance_of(Puppet::Configurer::Downloader).to receive(:evaluate) do |downloader|
        names << downloader.name
        []
      end

      pluginhandler.download_plugins(environment)
      expect(names).to eq(%w[pluginfacts plugin])
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
