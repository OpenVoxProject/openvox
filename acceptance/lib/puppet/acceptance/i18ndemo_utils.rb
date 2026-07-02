module Puppet
module Acceptance
  module I18nDemoUtils

    require 'puppet/acceptance/i18n_utils'
    extend Puppet::Acceptance::I18nUtils

    I18NDEMO_NAME = "i18ndemo"
    I18NDEMO_MODULE_NAME = "eputnam-#{I18NDEMO_NAME}"

    # Returns the command line to set system LANG for the given host.
    #
    # Debian-family platforms use update-locale (from the 'locales' package),
    # which writes /etc/default/locale directly. We avoid localectl there
    # because it routes through systemd-localed/polkit; starting with Debian 13
    # (trixie) that path denies Beaker's non-interactive SSH session with
    # "Failed to issue method call: Access denied". This change is expected
    # to filter down to Ubuntu and other Debian-based distros.
    #
    # Every other platform keeps using localectl, which works under their
    # default polkit policy.
    def set_system_locale_command(host, language)
      if %w[debian ubuntu].include?(host['platform'].variant)
        "update-locale LANG=#{language}"
      else
        "localectl set-locale LANG=#{language}"
      end
    end

    def configure_master_system_locale(requested_language)
      language = enable_locale_language(master, requested_language)
      fail_test("puppet server machine is missing #{requested_language} locale. help...") if language.nil?

      on(master, set_system_locale_command(master, language))
      on(master, puppet_resource('service', master['puppetservice'], 'ensure=stopped'))
      on(master, puppet_resource('service', master['puppetservice'], 'ensure=running'))
    end

    def reset_master_system_locale
      language = enable_locale_language(master, 'en_US')
      on(master, set_system_locale_command(master, language))
      on(master, puppet_resource('service', master['puppetservice'], 'ensure=stopped'))
      on(master, puppet_resource('service', master['puppetservice'], 'ensure=running'))
    end

    def install_i18n_demo_module(node, environment=nil)
      env_options = environment.nil? ? '' : "--environment #{environment}"
      on(node, puppet("module install #{I18NDEMO_MODULE_NAME} #{env_options}"))
    end

    def uninstall_i18n_demo_module(node, environment=nil)
      env_options = environment.nil? ? '' : "--environment #{environment}"
      [I18NDEMO_MODULE_NAME, 'puppetlabs-stdlib', 'puppetlabs-translate'].each do |module_name|
        on(node, puppet("module uninstall #{module_name} #{env_options}"), :acceptable_exit_codes => [0,1])
      end
      var_dir = on(node, puppet('config print vardir')).stdout.chomp
      on(node, "rm -rf '#{File.join(var_dir, 'locales', 'ja')}' '#{File.join(var_dir, 'locales', 'fi')}'")
    end
  end
end
end
