# Verify that -p loads external and custom facts from puppet locations
test_name "C14783: puppet facts show loads facts from puppet" do
  tag 'audit:high'

  agents.each do |agent|
    external_dir = agent.puppet['pluginfactdest']
    external_file = File.join(external_dir, "external.txt")
    custom_dir = File.join(agent.puppet['plugindest'], "facter")
    custom_file = File.join(custom_dir, 'custom.rb')

    teardown do
      agent.rm_rf(external_file)
      agent.rm_rf(custom_dir)
    end

    step "Agent #{agent}: create external fact" do
      agent.mkdir_p(external_dir)
      create_remote_file(agent, external_file, "external=external")
    end

    step "Agent #{agent}: create custom fact" do
      agent.mkdir_p(custom_dir)
      create_remote_file(agent, custom_file, "Facter.add(:custom) { setcode { 'custom' } }")
    end

    step "Agent #{agent}: verify facts" do
      on(agent, puppet("facts show external")) do |puppet_output|
        assert_match(/"external": "external"/, puppet_output.stdout.chomp)
      end

      on(agent, puppet("facts show custom")) do |puppet_output|
        assert_match(/"custom": "custom"/, puppet_output.stdout.chomp)
      end
    end
  end
end
