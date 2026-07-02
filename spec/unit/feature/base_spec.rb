require 'spec_helper'

require 'puppet/feature/base'

describe "Puppet features" do
  describe ":posix" do
    let(:features) { Puppet::Util::Feature.new('puppet/feature') }

    before do
      features.add(:syslog, :libs => ["syslog"])
      features.add(:posix) do
        require 'etc'
        !Puppet::Util::Platform.windows? && !Etc.getpwuid(0).nil?
      end
    end

    it "is true on a non-Windows system where POSIX user functions work" do
      allow(Puppet::Util::Platform).to receive(:windows?).and_return(false)
      allow(Etc).to receive(:getpwuid).with(0).and_return(Etc::Passwd.new('root'))

      expect(features.posix?).to eq(true)
    end

    it "is false on Windows" do
      allow(Puppet::Util::Platform).to receive(:windows?).and_return(true)

      expect(features.posix?).to eq(false)
    end

    it "does not invoke Etc.getpwuid on Windows" do
      allow(Puppet::Util::Platform).to receive(:windows?).and_return(true)
      expect(Etc).not_to receive(:getpwuid)

      features.posix?
    end

    it "does not depend on the syslog library being loadable" do
      allow(Puppet::Util::Platform).to receive(:windows?).and_return(false)
      allow(Etc).to receive(:getpwuid).with(0).and_return(Etc::Passwd.new('root'))
      # Simulate syslog gem not being installed.
      features.add(:syslog, :libs => ["nonexistent-syslog-library-#{SecureRandom.hex(4)}"])

      expect(features.syslog?).to eq(false)
      expect(features.posix?).to eq(true)
    end
  end
end
