# coding: utf-8
require 'spec_helper'
require 'puppet/util/json'

describe Puppet::Util::Json do
  include PuppetSpec::Files

  shared_examples_for 'json file loader' do |load_method|
    it 'reads a JSON file from disk' do
      file_path = file_containing('input', JSON.dump({ "my" => "data" }))

      expect(load_method.call(file_path)).to eq({ "my" => "data" })
    end

    it 'reads JSON as UTF-8' do
      file_path = file_containing('input', JSON.dump({ "my" => "𠜎" }))

      expect(load_method.call(file_path)).to eq({ "my" => "𠜎" })
    end
  end

  context "#load" do
    it 'raises an error if JSON is invalid' do
      expect {
        Puppet::Util::Json.load('{ invalid')
      }.to raise_error(Puppet::Util::Json::ParseError)
    end

    it 'raises an error if the content is empty' do
      expect {
        Puppet::Util::Json.load('')
      }.to raise_error(Puppet::Util::Json::ParseError)
    end

    it 'loads true' do
      expect(Puppet::Util::Json.load('true')).to eq(true)
    end

    it 'loads false' do
      expect(Puppet::Util::Json.load('false')).to eq(false)
    end

    it 'loads a numeric' do
      expect(Puppet::Util::Json.load('42')).to eq(42)
    end

    it 'loads a string' do
      expect(Puppet::Util::Json.load('"puppet"')).to eq('puppet')
    end

    it 'loads an array' do
      expect(Puppet::Util::Json.load(<<~JSON)).to eq([1, 2])
        [1, 2]
      JSON
    end

    it 'loads a hash' do
      expect(Puppet::Util::Json.load(<<~JSON)).to eq('a' => 1, 'b' => 2)
        {
          "a": 1,
          "b": 2
        }
      JSON
    end

    it 'passes options to the parser' do
      expect(Puppet::Util::Json.load('{"a": 1}', symbolize_names: true)).to eq(a: 1)
    end

    it 'translates symbolize_keys to symbolize_names' do
      expect(Puppet::Util::Json.load('{"a": 1}', symbolize_keys: true)).to eq(a: 1)
    end

    it 'does not modify the options it is given' do
      options = { symbolize_keys: true }
      Puppet::Util::Json.load('{"a": 1}', options)

      expect(options).to eq(symbolize_keys: true)
    end

    it 'loads from an IO' do
      expect(Puppet::Util::Json.load(StringIO.new('{"a": 1}'))).to eq('a' => 1)
    end
  end

  context "#dump" do
    let(:data) { { 'a' => [1, { 'b' => nil }] } }

    it 'dumps compact JSON by default' do
      expect(Puppet::Util::Json.dump(data)).to eq('{"a":[1,{"b":null}]}')
    end

    it 'pretty prints when pretty is set' do
      expect(Puppet::Util::Json.dump(data, pretty: true)).to eq(<<~JSON.chomp)
        {
          "a": [
            1,
            {
              "b": null
            }
          ]
        }
      JSON
    end

    it 'dumps a scalar' do
      expect(Puppet::Util::Json.dump(42, pretty: true)).to eq('42')
    end

    it 'ignores the obsolete quirks_mode option' do
      expect(Puppet::Util::Json.dump(data, pretty: true, quirks_mode: true)).to eq(JSON.pretty_generate(data))
    end

    it 'passes generator options through' do
      expect(Puppet::Util::Json.dump(data, space: ' ')).to eq('{"a": [1,{"b": null}]}')
    end

    it 'accepts a JSON::State when called recursively' do
      state = JSON::State.new(indent: '  ', object_nl: "\n")

      expect(Puppet::Util::Json.dump(data, state)).to eq(data.to_json(state))
    end

    it 'does not modify the options it is given' do
      options = { pretty: true, quirks_mode: true }
      Puppet::Util::Json.dump(data, options)

      expect(options).to eq(pretty: true, quirks_mode: true)
    end
  end

  context "load_file_if_valid" do
    before do
      Puppet[:log_level] = 'debug'
    end

    it_should_behave_like 'json file loader', Puppet::Util::Json.method(:load_file_if_valid)

    it 'returns nil when the file is invalid JSON and debug logs about it' do
      file_path = file_containing('input', '{ invalid')
      expect(Puppet).to receive(:debug)
        .with(/Could not retrieve JSON content/).and_call_original

      expect(Puppet::Util::Json.load_file_if_valid(file_path)).to eql(nil)
    end

    it 'returns nil when the filename is illegal and debug logs about it' do
      expect(Puppet).to receive(:debug)
        .with(/Could not retrieve JSON content .+: (?:path ?name|string) contains null byte/).and_call_original

      expect(Puppet::Util::Json.load_file_if_valid("not\0allowed")).to eql(nil)
    end

    it 'returns nil when the file does not exist and debug logs about it' do
      expect(Puppet).to receive(:debug)
        .with(/Could not retrieve JSON content .+: No such file or directory/).and_call_original

      expect(Puppet::Util::Json.load_file_if_valid('does/not/exist.json')).to eql(nil)
    end
  end

  context '#load_file' do
    it_should_behave_like 'json file loader', Puppet::Util::Json.method(:load_file)

    it 'raises an error when the file is invalid JSON' do
      file_path = file_containing('input', '{ invalid')

      expect {
        Puppet::Util::Json.load_file(file_path)
      }.to raise_error(Puppet::Util::Json::ParseError)
    end

    it 'raises an error when the filename is illegal' do
      expect {
        Puppet::Util::Json.load_file("not\0allowed")
      }.to raise_error(ArgumentError, /null byte/)
    end

    it 'raises an error when the file does not exist' do
      expect {
        Puppet::Util::Json.load_file('does/not/exist.json')
      }.to raise_error(Errno::ENOENT, /No such file or directory/)
    end

    it 'writes data formatted as JSON to disk' do
      file_path = file_containing('input', Puppet::Util::Json.dump({ "my" => "data" }))

      expect(Puppet::Util::Json.load_file(file_path)).to eq({ "my" => "data" })
    end
  end
end
