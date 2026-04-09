# frozen_string_literal: true

require_relative '../../puppet/provider'

class Puppet::Provider::Package < Puppet::Provider
  # Prefetch our package list, yo.
  def self.prefetch(packages)
    instances.each do |prov|
      pkg = packages[prov.name]
      if pkg
        pkg.provider = prov
      end
    end
  end

  # Clear out the cached values.
  def flush
    @property_hash.clear
  end

  # Look up the current status.
  def properties
    if @property_hash.empty?
      # For providers that support purging, default to purged; otherwise default to absent
      # Purged is the "most uninstalled" a package can be, so a purged package will be in-sync with
      # either `ensure => absent` or `ensure => purged`; an absent package will be out of sync with `ensure => purged`.
      default_status = self.class.feature?(:purgeable) ? :purged : :absent
      @property_hash = query || { :ensure => default_status }
      @property_hash[:ensure] = default_status if @property_hash.empty?
    end
    @property_hash.dup
  end

  def validate_source(value)
    true
  end

  # @return [Hash<String, String>] Environment variables parsed from the resource's
  #   `environment` parameter, or an empty hash if none are set.
  # @api private
  def package_environment
    env = {}

    return env unless resource.respond_to?(:parameters)

    env_param = resource.parameters[:environment]
    return env unless env_param

    envlist = env_param.value
    return env unless envlist

    envlist = [envlist] unless envlist.is_a? Array
    envlist.each do |setting|
      unless (match = /\A(\w+)=((.|\n)*)\z/.match(setting))
        warning _("Cannot understand environment setting %{setting}") % { setting: setting.inspect }
        next
      end
      var = match[1]
      value = match[2]

      if env.include?(var)
        warning _("Overriding environment setting '%{var}'") % { var: var }
      end

      if value.nil? || value.empty?
        msg = _("Empty environment setting '%{var}'") % { var: var }
        Puppet.warn_once('undefined_variables', "empty_env_var_#{var}", msg, resource.file, resource.line)
      end

      env[var] = value
    end

    env
  end

  # Injects the resource's environment variables into execute calls via
  # `:custom_environment`. Providers using `execute()` directly get this
  # automatically.
  def execute(*args)
    env = package_environment
    unless env.empty?
      if args.last.is_a?(Hash)
        existing = args.last[:custom_environment] || {}
        args.last[:custom_environment] = existing.merge(env)
      else
        args << { :custom_environment => env }
      end
    end
    super(*args)
  end

  # Wraps a block with the resource's environment variables applied via
  # `Puppet::Util.withenv`. Use this around named command methods (e.g.
  # `aptget`, `dpkg`, `rpm`) that bypass instance-level `execute`.
  # @api private
  def with_environment(&block)
    env = package_environment
    if env.empty?
      yield
    else
      Puppet::Util.withenv(env, &block)
    end
  end

  # Turns a array of options into flags to be passed to a command.
  # The options can be passed as a string or hash. Note that passing a hash
  # should only be used in case --foo=bar must be passed,
  # which can be accomplished with:
  #     install_options => [ { '--foo' => 'bar' } ]
  # Regular flags like '--foo' must be passed as a string.
  # @param options [Array]
  # @return Concatenated list of options
  # @api private
  def join_options(options)
    return unless options

    options.collect do |val|
      case val
      when Hash
        val.keys.sort.collect do |k|
          "#{k}=#{val[k]}"
        end
      else
        val
      end
    end.flatten
  end
end
