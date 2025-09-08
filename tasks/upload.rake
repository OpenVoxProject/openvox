namespace :vox do
  desc 'Upload artifacts from the output directory to S3. Requires the AWS CLI to be installed and configured appropriately.'
  task :upload, [:tag, :platform] do |_, args|
    endpoint = ENV.fetch('ENDPOINT_URL')
    bucket = ENV.fetch('BUCKET_NAME')
    component = 'openvox-agent'
    os = nil
    arch = nil
    if args[:platform]
      parts = args[:platform].split('-')
      os = parts[0].gsub('fedora','fc')
      osver = parts[1]
      # On MacOS, the dmg name has "macos.all"
      os = os == 'macos' ? "#{os}.#{osver}" : "#{os}#{osver}"
      arch = parts[2]
    end

    abort 'You must set the ENDPOINT_URL environment variable to the S3 server you want to upload to.' if endpoint.nil? || endpoint.empty?
    abort 'You must set the BUCKET_NAME environment variable to the S3 bucket you are uploading to.' if bucket.nil? || bucket.empty?
    abort 'You must provide a tag.' if args[:tag].nil? || args[:tag].empty?

    munged_tag = args[:tag].gsub('-', '.')
    s3 = "aws s3 --endpoint-url=#{endpoint}"

    # Ensure the AWS CLI isn't going to fail with the given parameters
    run_command("#{s3} ls s3://#{bucket}/")

    glob = "#{__dir__}/../packaging/output/**/*#{munged_tag}*"
    if os
      if os =~ /windows/
        # We don't put the OS in the filename for Windows
        glob += "#{arch}.msi"
      else
        # "arch" is not used here because we are currently horrifyingly
        # inconsistent with the platform -> package name
        # (e.g. debian-12-aarch64 ends up as debian12.arm64).
        glob += "#{os}*"
      end
    end
    puts "Searching for files with glob #{glob}"
    files = Dir.glob(glob)
    abort 'No files for the given tag found in the output directory.' if files.empty?

    path = "s3://#{bucket}/#{component}/#{args[:tag]}"
    files.each do |f|
      f = `cygpath -m #{f}`.chomp if os =~ /windows/
      run_command("#{s3} cp #{f} #{path}/#{File.basename(f)}", silent: false)
    end
  end
end
