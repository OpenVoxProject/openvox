# frozen_string_literal: true

require_relative '../../../puppet/indirector/code'
require 'hiera/scope'

class Puppet::DataBinding::Hiera < Puppet::Indirector::Code
  desc "Retrieve data using Hiera."

  def initialize(*args)
    unless Puppet.features.hiera?
      # TRANSLATORS "Hiera" is the name of a code library and should not be translated
      raise _("Hiera terminus not supported without hiera library")
    end

    super
  end

  if defined?(::Psych::SyntaxError)
    DATA_BINDING_EXCEPTIONS = [::StandardError, ::Psych::SyntaxError]
  else
    DATA_BINDING_EXCEPTIONS = [::StandardError]
  end

  def find(request)
    not_found = Object.new
    options = request.options
    Puppet.debug { "Performing a hiera indirector lookup of #{request.key} with options #{options.inspect}" }
    value = hiera.lookup(request.key, not_found, Hiera::Scope.new(options[:variables]), nil, convert_merge(options[:merge]))
    throw :no_such_key if value.equal?(not_found)
    value
  rescue *DATA_BINDING_EXCEPTIONS => detail
    error = Puppet::DataBinding::LookupError.new("DataBinding 'hiera': #{detail.message}")
    error.set_backtrace(detail.backtrace)
    raise error
  end

  private

  # Converts a lookup 'merge' parameter argument into a Hiera 'resolution_type' argument.
  #
  # @param merge [String,Hash,nil] The lookup 'merge' argument
  # @return [Symbol,Hash,nil] The Hiera 'resolution_type'
  def convert_merge(merge)
    case merge
    when nil, 'first'
      # Nil is OK. Defaults to Hiera :priority
      nil
    when Puppet::Pops::MergeStrategy
      convert_merge(merge.configuration)
    when 'unique'
      # Equivalent to Hiera :array
      :array
    when 'hash'
      # Equivalent to Hiera :hash with default :native merge behavior. A Hash must be passed here
      # to override possible Hiera deep merge config settings.
      { :behavior => :native }
    when 'deep'
      # Equivalent to Hiera :hash with :deeper merge behavior.
      { :behavior => :deeper }
    when Hash
      strategy = merge['strategy']
      if strategy == 'deep'
        result = { :behavior => :deeper }
        # Remaining entries must have symbolic keys
        merge.each_pair { |k, v| result[k.to_sym] = v unless k == 'strategy' }
        result
      else
        convert_merge(strategy)
      end
    else
      # TRANSLATORS "merge" is a parameter name and should not be translated
      raise Puppet::DataBinding::LookupError, _("Unrecognized value for request 'merge' parameter: '%{merge}'") % { merge: merge }
    end
  end

  public

  def self.hiera_config
    hiera_config = Puppet.settings[:hiera_config]
    config = {}

    if Puppet::FileSystem.exist?(hiera_config)
      config = Hiera::Config.load(hiera_config)
    else
      Puppet.warning _("Config file %{hiera_config} not found, using Hiera defaults") % { hiera_config: hiera_config }
    end

    config[:logger] = 'puppet'
    config
  end

  def self.hiera
    @hiera ||= Hiera.new(:config => hiera_config)
  end

  def hiera
    self.class.hiera
  end
end
