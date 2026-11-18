require 'open3'

module PuppetSpec
  module Execution
    def self.with_executor
      return yield unless Puppet::Util::Platform.jruby?

      begin
        # simulate what openvox-server does
        Puppet::Util::ExecutionStub.set do |command, options, _stdin, stdout, stderr|
          Dir.chdir(options[:cwd] || Dir.pwd) do
            out, err, status = Open3.capture3(*command)
            stdout.write(out)
            stderr.write(err)
            if options[:failonfail] && !status.success?
              raise Puppet::ExecutionFailure, "Execution of '#{Array(command).join(' ')}' returned #{status.exitstatus}: #{out.strip}"
            end

            out
          end
        end
        yield
      ensure
        Puppet::Util::ExecutionStub.reset
      end
    end
  end
end
