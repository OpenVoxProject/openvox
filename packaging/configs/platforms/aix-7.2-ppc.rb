platform "aix-7.2-ppc" do |plat|
  plat.servicetype "aix"

  plat.make "gmake"
  plat.tar "/opt/freeware/bin/tar"
  plat.rpmbuild "/usr/bin/rpm"
  plat.patch "/opt/freeware/bin/patch"

  # Basic vanagon operations require mktemp, rsync, coreutils, make, tar and sed so leave this in there
  plat.provision_with "rpm -Uvh --replacepkgs http://osmirror.delivery.puppetlabs.net/AIX_MIRROR/mktemp-1.7-1.aix5.1.ppc.rpm http://osmirror.delivery.puppetlabs.net/AIX_MIRROR/rsync-3.0.6-1.aix5.3.ppc.rpm http://osmirror.delivery.puppetlabs.net/AIX_MIRROR/coreutils-5.2.1-2.aix5.1.ppc.rpm http://osmirror.delivery.puppetlabs.net/AIX_MIRROR/sed-4.1.1-1.aix5.1.ppc.rpm http://osmirror.delivery.puppetlabs.net/AIX_MIRROR/make-3.80-1.aix5.1.ppc.rpm http://osmirror.delivery.puppetlabs.net/AIX_MIRROR/tar-1.22-1.aix6.1.ppc.rpm"

  # lots of things expect mktemp to be installed in the usual place, so link it
  plat.provision_with "ln -sf /opt/freeware/bin/mktemp /usr/bin/mktemp"

  # We use --force with rpm because the pl-gettext and pl-autoconf
  # packages conflict with a charset.alias file.
  #
  # Until we get those packages to not conflict (or we remove the need
  # for pl-autoconf) we'll need to force the installation
  #                                         Sean P. McD.
  plat.install_build_dependencies_with "rpm -Uvh --replacepkgs --force "
  plat.vmpooler_template "aix-7.2-power"
end
