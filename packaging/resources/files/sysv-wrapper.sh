#!/bin/sh

# We keep around any paths in LD_LIBRARY_PATH that start with /opt/rh/. Those paths are
# from redhat software collections packages and are required for things like SCL python
# to work. See PUP-8351.
STRIP_LDLYP_COMMAND=" \
if ENV['LD_LIBRARY_PATH']; \
  print ENV['LD_LIBRARY_PATH'].split(':', -1).keep_if { |path| path.start_with?('/opt/rh/') }.join(':') \
end"
LD_LIBRARY_PATH=`/opt/puppetlabs/puppet/bin/ruby -e "$STRIP_LDLYP_COMMAND"`
export LD_LIBRARY_PATH
unset LD_PRELOAD
unset GEM_HOME
unset GEM_PATH
unset DLN_LIBRARY_PATH
unset RUBYLIB
unset RUBYLIB_PREFIX
unset RUBYOPT
unset RUBYPATH
unset RUBYSHELL

# If $PATH does not match a regex for /opt/puppetlabs/bin
if [ `expr "${PATH}" : '.*/opt/puppetlabs/bin'` -eq 0 ]; then
  # Add /opt/puppetlabs/bin to a possibly empty $PATH
  PATH="${PATH:+${PATH}:}/opt/puppetlabs/bin"
  export PATH
fi

COMMAND=`basename "${0}"`

exec /opt/puppetlabs/puppet/bin/${COMMAND} "$@"
