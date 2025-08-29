require 'puppet/acceptance/common_utils'
extend Puppet::Acceptance::CommandUtils

confine :except, :platform => 'windows'

def libsource(host)
  kernel = on(host, facter("kernel")).stdout.chomp.downcase
  arch = on(host, facter("architecture")).stdout.chomp.downcase

  case kernel
  when "linux"
    case arch
    when "x86_64", "amd64"
      "libexplode.so.linux64"
    when "i386"
      "libexplode.so.linux32"
    else
      nil
    end
  when "aix"
    "libexplode.so.aix"
  when "sunos"
    case arch
    when "i86sol"
      "libexplode.so.solaris"
    else
      nil
    end
  else
    nil
  end
end

def libdest(host)
  kernel = on(host, facter("kernel")).stdout.chomp.downcase

  case kernel
  when "aix"
    "libruby.so"
  when "sunos"
    "libm.so.2"
  else
    "libm.so.6"
  end
end

test_name 'PA-437: cleanup linker environment' do
  skip_test 'requires wrapper script which is created by the AIO' if [:gem, :git].include?(@options[:type])

  fixtures = File.dirname(__FILE__) + "/../fixtures/dyld/"
  dirs = {}
  libs = {}

  step "Lay down a crashing library on the SUT" do
    agents.each do |agent|
      source = libsource(agent)
      if source == nil then
        libs[agent] = nil
        dirs[agent] = nil
        next
      end
      dirs[agent] = agent.tmpdir("lib") + "/"
      libs[agent] = dirs[agent] + libdest(agent)
      fixture = fixtures + source

      scp_to(agent, fixture, libs[agent])
    end
  end

  teardown do
    agents.each do |agent|
      next if dirs[agent] == nil
      on agent, "rm -rf #{dirs[agent]}"
    end
  end

  step "Put the crashing library on the load path" do
    agents.each do |agent|
      next if dirs[agent] == nil
      kernel = on(agent, facter("kernel")).stdout.downcase.strip

      var = case kernel
            when "aix"
              "LIBPATH"
            else
              "LD_LIBRARY_PATH"
            end
      on agent, puppet("--version"), :environment => { var => dirs[agent] }
    end
  end
end
