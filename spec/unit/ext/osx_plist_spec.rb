require 'spec_helper'
require 'puppet/util/plist'

describe "ext/osx/puppet.plist", :if => Puppet.features.cfpropertylist? do
  let(:plist_path) { File.expand_path('../../../ext/osx/puppet.plist', __dir__) }
  let(:plist) { Puppet::Util::Plist.read_plist_file(plist_path) }

  # On macOS 26 and later the forked agent run crashes inside os_log when it
  # resolves an IPv4-only hostname after the parent has refreshed its CA or
  # CRL. Disabling unified logging for the daemon avoids that path (GH-538).
  it "disables unified logging for the agent daemon" do
    expect(plist['EnvironmentVariables']).to include('OS_ACTIVITY_MODE' => 'disable')
  end

  # OS_ACTIVITY_MODE=disable also silences syslog(3), so the daemon must not
  # rely on the macOS default log destination.
  it "logs to the console rather than syslog" do
    args = plist['ProgramArguments']
    expect(args).to include('--logdest')
    expect(args[args.index('--logdest') + 1]).to eq('console')
  end
end
