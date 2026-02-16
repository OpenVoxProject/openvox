platform "astra-1.8-amd64" do |plat|
  plat.servicedir "/lib/systemd/system"
  plat.defaultdir "/etc/default"
  plat.configdir "/etc"
  plat.servicetype "systemd"
  plat.codename "bookworm"

  packages = ['build-essential', 'devscripts', 'rsync', 'fakeroot', 'debhelper']
  plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"
  plat.install_build_dependencies_with "DEBIAN_FRONTEND=noninteractive; apt-get install -qy --no-install-recommends "
end
