component "module-puppetlabs-yumrepo_core" do |pkg, settings, platform|
  pkg.load_from_json("configs/components/module-puppetlabs-yumrepo_core.json")

  instance_eval File.read("configs/components/_base-module.rb")
end
