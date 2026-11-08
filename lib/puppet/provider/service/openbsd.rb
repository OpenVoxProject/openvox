# frozen_string_literal: true

Puppet::Type.type(:service).provide :openbsd, :parent => :init do
  desc "Provider for OpenBSD's rc.d daemon control scripts"

  commands :rcctl => '/usr/sbin/rcctl'

  confine 'os.name' => :openbsd
  defaultfor 'os.name' => :openbsd
  has_feature :flaggable

  def startcmd
    [command(:rcctl), '-f', :start, @resource[:name]]
  end

  def stopcmd
    [command(:rcctl), :stop, @resource[:name]]
  end

  def restartcmd
    [command(:rcctl), '-f', :restart, @resource[:name]]
  end

  def statuscmd
    [command(:rcctl), :check, @resource[:name]]
  end

  def enabled?
    output = execute([command(:rcctl), "get", @resource[:name], "status"],
                     :failonfail => false, :combine => false, :squelch => false)

    if output.exitstatus == 1
      debug("Is disabled")
      :false
    else
      debug("Is enabled")
      :true
    end
  end

  def enable
    debug("Enabling")
    rcctl(:enable, @resource[:name])
    if @resource[:flags]
      rcctl(:set, @resource[:name], :flags, @resource[:flags])
    end
  end

  def disable
    debug("Disabling")
    rcctl(:disable, @resource[:name])
  end

  def running?
    output = execute([command(:rcctl), "check", @resource[:name]],
                     :failonfail => false, :combine => false, :squelch => false).chomp
    true if output =~ /\(ok\)/
  end

  # Disabled services always have 'NO' flags.
  def flags
    output = execute([command(:rcctl), "get", @resource[:name], "flags"],
                     :failonfail => false, :combine => false, :squelch => false).chomp
    debug("Flags are: \"#{output}\"")
    output unless %w[YES NO].include?(output)
  end

  def flags=(value)
    debug("Changing flags from #{flags} to #{value}")
    rcctl(:set, @resource[:name], :flags, value)
    # If the service is already running, force a restart as the flags have been changed.
    rcctl(:restart, @resource[:name]) if running?
  end
end
