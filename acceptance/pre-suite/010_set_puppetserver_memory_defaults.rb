# Tune puppetserver java to half the system memory.
test_name 'Set Puppetserver Memory Defaults' do
  skip_test 'No primary node to configure Puppetserver memory defaults for' unless master

  mem_in_bytes = on(master, 'facter memory.system.total_bytes').stdout.strip
  megabytes = 1024 * 1024
  half_mem = (mem_in_bytes.to_i / megabytes / 2)

  defaults_dir = case master.platform
                 when /debian|ubuntu/ then  '/etc/default'
                 else '/etc/sysconfig'
                 end

  if half_mem > 2048
    on(master, "sed -i -E -e '/^JAVA_ARGS=/ s/-Xms[0-9]+[m|g] -Xmx[0-9]+[m|g]/-Xms#{half_mem}m -Xmx#{half_mem}m/' #{defaults_dir}/puppetserver")
    on(master, "cat #{defaults_dir}/puppetserver")
  else
    logger.info("System memory on the primary is less than 4GB (#{(mem_in_bytes.to_i / megabytes)}m). Leaving the defult 2GB for Puppetserver memory.")
  end
end
