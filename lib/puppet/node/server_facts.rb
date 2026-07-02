# frozen_string_literal: true

class Puppet::Node::ServerFacts
  def self.load
    server_facts = {}

    # Add implementation information
    server_facts["serverimplementation"] = Puppet.implementation

    # Add our server version to the fact list
    server_facts["serverversion"] = Puppet.version.to_s

    # And then add the server name and IP
    { "servername" => "networking.fqdn",
      "serverip" => "networking.ip",
      "serverip6" => "networking.ip6" }.each do |var, fact|
      value = Puppet.runtime[:facter].value(fact)
      unless value.nil?
        server_facts[var] = value
      end
    end

    if server_facts["servername"].nil?
      host = Puppet.runtime[:facter].value('networking.hostname')
      if host.nil?
        Puppet.warning _("Could not retrieve fact servername")
      elsif domain = Puppet.runtime[:facter].value('networking.domain') # rubocop:disable Lint/AssignmentInCondition
        server_facts["servername"] = [host, domain].join(".")
      else
        server_facts["servername"] = host
      end
    end

    if server_facts["serverip"].nil? && server_facts["serverip6"].nil?
      Puppet.warning _("Could not retrieve either serverip or serverip6 fact")
    end

    server_facts
  end
end
