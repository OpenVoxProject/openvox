component "module-puppetlabs-sshkeys_core" do |pkg, settings, platform|
  pkg.load_from_json("configs/components/module-puppetlabs-sshkeys_core.json")

  instance_eval File.read("configs/components/_base-module.rb")
end
