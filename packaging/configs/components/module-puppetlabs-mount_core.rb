component "module-puppetlabs-mount_core" do |pkg, settings, platform|
  pkg.load_from_json("configs/components/module-puppetlabs-mount_core.json")

  instance_eval File.read("configs/components/_base-module.rb")
end
