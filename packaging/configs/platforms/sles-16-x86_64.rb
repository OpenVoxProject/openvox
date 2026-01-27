platform "sles-16-x86_64" do |plat|
  plat.inherit_from_default

  packages = %w[systemtap-sdt-devel]
  packages.each do |pkg|
    plat.provision_with "zypper install -y #{pkg}"
  end
end
