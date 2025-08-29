component "openssl-fips" do |pkg, settings, platform|

  raise "openssl-fips is not a valid component on non-fips platforms" unless platform.is_fips?

  pkg.build_requires "puppet-runtime"

  openssl_fips_details = JSON.parse(File.read('configs/components/openssl-fips.json'))
  openssl_fips_version = openssl_fips_details['version']
  openssl_fips_location = openssl_fips_details['location']

  tarball_name = "#{pkg.get_name}-#{openssl_fips_version}.#{platform.name}.tar.gz"
  pkg.url File.join(openssl_fips_location, tarball_name)
  pkg.sha1sum File.join(openssl_fips_location, "#{tarball_name}.sha1")
  pkg.version openssl_fips_version
  pkg.install_only true

  pkg.add_source("file://resources/patches/openssl/openssl-fips.cnf.patch")

  openssl_ssldir   = File.join(settings[:prefix], 'ssl')
  openssl_cnf      = File.join(openssl_ssldir, 'openssl.cnf')
  openssl_fips_cnf = File.join(openssl_ssldir, 'openssl-fips.cnf')

  # Overlay openssl-fips shared library onto puppet-runtime in /opt at *build* time
  #
  # Don't generate `fipsmodule.cnf` during the build. It must be generated
  # during postinstall action.
  #
  # Don't include FIPS-enabled `openssl.cnf` in the package. It must be moved
  # into place after `fipsmodule.cnf` is generated. So ship `openssl-fips.cnf`
  # and rename it to `openssl.cnf` during postinstall action.
  #
  extract_dir = platform.is_windows? ? '/cygdrive/c' : '/'
  pkg.install do
    [
      "#{platform.tar} --skip-old-files --directory=#{extract_dir} --extract --gunzip --file=#{tarball_name}",
      "mv #{openssl_cnf} #{openssl_fips_cnf}",
      "#{platform.patch} --strip=1 --fuzz=0 --ignore-whitespace --no-backup-if-mismatch -d #{openssl_ssldir}/ < openssl-fips.cnf.patch"
    ]
  end

  if platform.is_windows?
    # We need to include fipsmodule.cnf, but it's hard on Windows because the
    # installation directory is user-configurable and openssl doesn't support
    # "./fipsmodule.cnf" to mean look in the same directory as openssl.cnf.
    #
    # From https://www.openssl.org/docs/man3.0/man5/config.html
    #
    #   "The environment variable OPENSSL_CONF_INCLUDE, if it exists, is
    #   prepended to all relative pathnames. If the pathname is still relative,
    #   it is interpreted based on the current working directory."
    #
    # So to make it clear how the relative path is converted to absolute, specify
    # the environment variable directly in openssl-fips.cnf, which will be copied
    # to openssl.cnf during installation. Use \x24 to specify a literal '$'
    # character.
    pkg.install do
      ["sed -i 's|.include /opt/puppetlabs/puppet/ssl/fipsmodule.cnf|.include \\x24ENV::OPENSSL_CONF_INCLUDE/fipsmodule.cnf|' #{openssl_fips_cnf}"]
    end
  end

  # See "Making all applications use the FIPS module by default" in
  # https://www.openssl.org/docs/man3.0/man7/fips_module.html
  #
  # We have to run `openssl fipsinstall` to generate `fipsmodule.cnf`. This
  # generates an HMAC for the `fips.so` and stores that value in `fipsmodule.cnf`.
  # Only later can we enable fips, by overwriting `openssl.cnf` with the fips
  # enabled version.
  #
  # During an upgrade, `fips.so` may be modified, invaliding the checksum in
  # `fipsmodule.cnf`, and that will prevent `openssl fipsinstall` from working.
  # So override OPENSSL_CONF to use the pristine `openssl.cnf` without fips
  # enabled to regenerate `fipsmodule.conf`
  #
  if platform.is_rpm?
    # If you modify the following code, update customactions.wxs.erb too!
    pkg.add_postinstall_required_action ["install", "upgrade"],
      [<<-HERE.undent
        OPENSSL_CONF=/opt/puppetlabs/puppet/ssl/openssl.cnf.dist /opt/puppetlabs/puppet/bin/openssl fipsinstall -module /opt/puppetlabs/puppet/lib/ossl-modules/fips.so -provider_name fips -out /opt/puppetlabs/puppet/ssl/fipsmodule.cnf
        /usr/bin/cp --preserve /opt/puppetlabs/puppet/ssl/openssl-fips.cnf /opt/puppetlabs/puppet/ssl/openssl.cnf
        /usr/bin/chmod 0644 /opt/puppetlabs/puppet/ssl/openssl.cnf
        /usr/bin/chmod 0644 /opt/puppetlabs/puppet/ssl/fipsmodule.cnf
        HERE
      ]

    # Delete generated files, they may not exist, so force
    #
    # REMIND: update for Windows
    pkg.add_preremove_action ["removal"], [
      "rm --force /opt/puppetlabs/puppet/ssl/openssl.cnf",
      "rm --force /opt/puppetlabs/puppet/ssl/fipsmodule.cnf"
    ]
  end
end
