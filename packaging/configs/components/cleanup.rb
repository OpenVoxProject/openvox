# This component exists only to remove unnecessary files that bloat the final puppet-agent package.
component "cleanup" do |pkg, settings, platform|
  unless settings[:dev_build]
    # Unless the settings specify that this is a development build, remove
    # unneeded header files (boost headers, for example, increase the size of
    # the package to an unacceptable degree).
    #
    # Note that:
    # - Ruby is not in this list because its headers are required to build native
    #   extensions for gems.
    # - Curl and OpenSSL are not in this list because their headers are
    #   required to build other libraries (e.g. libssh2 and libgit2) in other
    #   projects that rely on puppet-agent (e.g. pe-r10k-vanagon).
    unwanted_headers = ["augeas.h", "boost", "cpp-pcp-client", "fa.h",
                        "facter", "hocon", "leatherman", "libexslt", "libxml2",
                        "libxslt", "whereami", "yaml-cpp"]

    # We need a full path on windows because /usr/bin is not in the PATH at this point
    rm = platform.is_windows? ? '/usr/bin/rm' : 'rm'

    cleanup_steps = [
      unwanted_headers.map { |h| "#{rm} -rf #{settings[:includedir]}/#{h}" },
      # Also remove OpenSSL manpages
      "#{rm} -rf #{settings[:prefix]}/ssl/man",
    ]

    if platform.is_windows?
      # On Windows releases that distribute curl, these curl binaries can
      # interfere with the native ones when puppet-agent's bindir is in the PATH:
      cleanup_steps << "#{rm} #{settings[:bindir]}/curl*"
    end

    cleanup_steps << "#{rm} -rf #{settings[:service_conf]}"

    pkg.install { cleanup_steps }
  end
end
