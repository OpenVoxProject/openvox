component "module-puppetlabs-zfs_core" do |pkg, settings, platform|
  pkg.load_from_json("configs/components/module-puppetlabs-zfs_core.json")

  instance_eval File.read("configs/components/_base-module.rb")
end
