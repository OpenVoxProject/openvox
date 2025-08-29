# This lays down the execution_wrapper script, which used to be a piece of pxp-agent
# that Choria depends on, but is now a plain Ruby script.
component "execution_wrapper" do |pkg, settings, platform|
  pkg.add_source "file://resources/files/execution_wrapper"
  pkg.install_file "execution_wrapper", "#{settings[:bindir]}/execution_wrapper", mode: '0755'
end
