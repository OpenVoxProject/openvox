namespace :vox do
  desc 'Promote a component with a given ref into this repo. For puppet-runtime and pxp-agent, use the tag that has been built and uploaded to openvox-artifacts.'
  task :promote, [:component, :ref] do |_, args|
    component = args[:component]
    ref = args[:ref]

    abort 'You must specify a component.' if component.nil? || component.empty?
    abort "Could not find configs/components/#{component}.json" unless File.exist?("configs/components/#{component}.json")
    abort 'You must provide a ref.' if ref.nil? || ref.empty?

    if ['puppet-runtime', 'pxp-agent'].include?(component)
      munged = ref.gsub('-', '.')
      data = <<~DATA
        {"location":"https://s3.osuosl.org/openvox-artifacts/#{component}/#{ref}/","version":"#{munged}"}
      DATA
    else
      data = <<~DATA
        {"url":"https://github.com/openvoxproject/#{component}.git","ref":"#{ref}"}
      DATA
    end

    branch = run_command('git rev-parse --abbrev-ref HEAD')

    puts "Writing #{component}.json"
    File.write("configs/components/#{component}.json", data)
    run_command("git add configs/components/#{component}.json")
    puts 'Creating commit'
    run_command("git commit -m 'Promote #{component} #{ref}'")
    if ENV['NOPUSH'].nil?
      puts 'Pushing to origin'
      run_command("git push origin #{branch}")
    end
  end
end
