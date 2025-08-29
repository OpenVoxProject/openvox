component "module-puppetlabs-scheduled_task" do |pkg, settings, platform|
  pkg.load_from_json("configs/components/module-puppetlabs-scheduled_task.json")

  instance_eval File.read("configs/components/_base-module.rb")
end
