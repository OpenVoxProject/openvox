# Add /opt/puppetlabs/bin to the path for sh compatible users

if [ -z "${PATH-}" ] ; then
  export PATH=/opt/puppetlabs/bin
elif ! echo "${PATH}" | grep -q /opt/puppetlabs/bin ; then
  export PATH="${PATH}:/opt/puppetlabs/bin"
fi

if ! echo "${MANPATH-}" | grep -q /opt/puppetlabs/puppet/share/man ; then
  export MANPATH="${MANPATH-}:/opt/puppetlabs/puppet/share/man"
fi
