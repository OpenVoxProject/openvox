# Set TMPDIR on the primary so that mktemp creates directories outside /tmp.
# With systemd PrivateTmp=true on the puppetserver service, the server process
# gets its own /tmp namespace and can't see directories created there by beaker.
test_name('configure TMPDIR for PrivateTmp compatibility') do
  server_tmpdir = '/opt/puppetlabs/test-tmp'
  on(master, "mkdir -p #{server_tmpdir} && chown puppet #{server_tmpdir} && chmod 755 #{server_tmpdir}")
  master.add_env_var('TMPDIR', server_tmpdir)
end
