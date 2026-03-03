# frozen_string_literal: true

module Puppet::Util
  module Json
    class ParseError < StandardError
      attr_reader :cause, :data

      def self.build(original_exception, data)
        new(original_exception.message).tap do |exception|
          exception.instance_eval do
            @cause = original_exception
            set_backtrace original_exception.backtrace
            @data = data
          end
        end
      end
    end

    require 'json'

    # Load the content from a file as JSON if
    # contents are in valid format. This method does not
    # raise error but returns `nil` when invalid file is
    # given.
    def self.load_file_if_valid(filename, options = {})
      load_file(filename, options)
    rescue Puppet::Util::Json::ParseError, ArgumentError, Errno::ENOENT => detail
      Puppet.debug("Could not retrieve JSON content from '#{filename}': #{detail.message}")
      nil
    end

    # Load the content from a file as JSON.
    def self.load_file(filename, options = {})
      json = Puppet::FileSystem.read(filename, :encoding => 'utf-8')
      load(json, options)
    end

    # These methods do similar processing to the fallback implemented by MultiJson
    # when using the built-in JSON backend, to ensure consistent behavior
    # whether or not MultiJson can be loaded.
    def self.load(string, options = {})
      string = string.read if string.respond_to?(:read)

      options[:symbolize_names] = true if options.delete(:symbolize_keys)
      ::JSON.parse(string, options)
    rescue JSON::ParserError => e
      raise Puppet::Util::Json::ParseError.build(e, string)
    end

    def self.dump(object, options = {})
      # Options is a state when we're being called recursively
      if !options.is_a?(JSON::State) && options.delete(:pretty)
        options.merge!(::JSON::PRETTY_STATE_PROTOTYPE.to_h)
      end
      object.to_json(options)
    end
  end
end
