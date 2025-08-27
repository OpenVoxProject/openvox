platform "redhatfips-9-x86_64" do |plat|
  # NOTE: You must run the build on a FIPS-enabled Linux host in order for this platform to
  # build correctly with the Docker engine.
  plat.inherit_from_default
end
