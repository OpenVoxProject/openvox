# frozen_string_literal: true

config = Puppet::Util::Reference.newreference(:configuration, :depth => 1, :doc => "A reference for all settings") do
  str = +''
  unix_runmode_root = Puppet::Util::UnixRunMode.new(:server, true, false)
  unix_runmode_user = Puppet::Util::UnixRunMode.new(:server, false, false)
  windows_runmode = Puppet::Util::WindowsRunMode.new(:server, true, false)

  Puppet.settings.sort_by { |name, _| name.to_s }.each do |name, object|
    # Make each name an anchor
    header = name.to_s
    str << markdown_header(header, 3)

    # Print the doc string itself
    begin
      str << Puppet::Util::Docs.scrub(object.desc)
    rescue => detail
      Puppet.log_exception(detail)
    end
    str << "\n\n"

    # Now print the data about the item.
    val = case name.to_s
          when 'vardir'
            "Unix/Linux: #{unix_runmode_root.var_dir} -- Windows: #{windows_runmode.var_dir} -- Non-root user: #{unix_runmode_user.var_dir}"
          when 'publicdir'
            "Unix/Linux: #{unix_runmode_root.public_dir} -- Windows: #{windows_runmode.public_dir} -- Non-root user: #{unix_runmode_user.public_dir}"
          when 'confdir'
            "Unix/Linux: #{unix_runmode_root.conf_dir} -- Windows: #{windows_runmode.conf_dir} -- Non-root user: #{unix_runmode_user.conf_dir}"
          when 'codedir'
            "Unix/Linux: #{unix_runmode_root.code_dir} -- Windows: #{windows_runmode.code_dir} -- Non-root user: #{unix_runmode_user.code_dir}"
          when 'rundir'
            "Unix/Linux: #{unix_runmode_root.run_dir} -- Windows: #{windows_runmode.run_dir} -- Non-root user: #{unix_runmode_user.run_dir}"
          when 'logdir'
            "Unix/Linux: #{unix_runmode_root.log_dir} -- Windows: #{windows_runmode.log_dir} -- Non-root user: #{unix_runmode_user.log_dir}"
          when 'hiera_config'
            '$confdir/hiera.yaml. However, for backwards compatibility, if a file exists at $codedir/hiera.yaml, Puppet uses that instead.'
          when 'certname'
            "the Host's fully qualified domain name, as determined by Facter"
          when 'hostname'
            "(the system's fully qualified hostname)"
          when 'domain'
            "(the system's own domain)"
          when 'srv_domain'
            'example.com'
          when 'http_user_agent'
            'Puppet/<version> Ruby/<version> (<architecture>)'
          else
            object.default
          end

    # Leave out the section information; it was apparently confusing people.
    # str << "- **Section**: #{object.section}\n"
    unless val == ""
      str << "- *Default*: `#{val}`\n"
    end
    str << "\n"
  end

  return str
end

config.header = <<~EOT
  ## Configuration settings

  * Each of these settings can be specified in `puppet.conf` or on the
    command line.
  * Puppet Enterprise (PE) and open source Puppet share the configuration settings
    documented here. However, PE defaults differ from open source defaults for some
    settings, such as `node_terminus`, `storeconfigs`, `always_retry_plugins`,
    `disable18n`, `environment_timeout` (when Code Manager is enabled), and the
    Puppet Server JRuby `max-active-instances` setting. To verify PE configuration
    defaults, check the `puppet.conf` or `pe-puppet-server.conf` file after
    installation.
  * When using boolean settings on the command line, use `--setting` and
    `--no-setting` instead of `--setting (true|false)`. (Using `--setting false`
    results in "Error: Could not parse application options: needless argument".)
  * Settings can be interpolated as `$variables` in other settings; `$environment`
    is special, in that puppet master will interpolate each agent node's
    environment instead of its own.
  * Multiple values should be specified as comma-separated lists; multiple
    directories should be separated with the system path separator (usually
    a colon).
  * Settings that represent time intervals should be specified in duration format:
    an integer immediately followed by one of the units 'y' (years of 365 days),
    'd' (days), 'h' (hours), 'm' (minutes), or 's' (seconds). The unit cannot be
    combined with other units, and defaults to seconds when omitted. Examples are
    '3600' which is equivalent to '1h' (one hour), and '1825d' which is equivalent
    to '5y' (5 years).
  * If you use the `splay` setting, note that the period that it waits changes
    each time the Puppet agent is restarted.
  * Settings that take a single file or directory can optionally set the owner,
    group, and mode for their value: `rundir = $vardir/run { owner = puppet,
    group = puppet, mode = 644 }`
  * The Puppet executables ignores any setting that isn't relevant to
    their function.

  See the [configuration guide][confguide] for more details.

  [confguide]: https://puppet.com/docs/puppet/latest/config_about_settings.html


EOT
