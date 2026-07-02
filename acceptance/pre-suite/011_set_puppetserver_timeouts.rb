test_name 'Set Puppetserver start and reload timeouts' do
  skip_test 'No primary node to configure Puppetserver timeouts for' unless master

  start_timeout = options['puppetserver-start-timeout']
  reload_timeout = options['puppetserver-reload-timeout']
  skip_test 'No timeout options specified, skipping' if (start_timeout.nil? && reload_timeout.nil?)

  # Update the defaults used internally by the puppetserver
  # service scripts.
  defaults_dir = case master.platform
                 when /debian|ubuntu/ then  '/etc/default'
                 else '/etc/sysconfig'
                 end

  exprs = []
  exprs <<  "-e '/^START_TIMEOUT=/ s/=.*$/=#{start_timeout}/'" if !start_timeout.nil?
  exprs <<  "-e '/^RELOAD_TIMEOUT=/ s/=.*$/=#{reload_timeout}/'" if !reload_timeout.nil?
  on(master, "sed -i #{exprs.join(' ')} #{defaults_dir}/puppetserver")
  on(master, "cat #{defaults_dir}/puppetserver")

  # And update the defaults used by the systemd service unit.
  # Puppetserver will effectively timeout a start at whichever
  # is shorter...
  if !start_timeout.nil?
    dropin_dir = '/etc/systemd/system/puppetserver.service.d'
    on(master, <<~EOS)
      mkdir -p #{dropin_dir}
      printf '[Service]\\nTimeoutStartSec=#{start_timeout}\\n' \
        > #{dropin_dir}/timeouts.conf
    EOS
    on(master, 'systemctl daemon-reload')
    on(master, 'systemctl cat puppetserver.service')
  end
end
