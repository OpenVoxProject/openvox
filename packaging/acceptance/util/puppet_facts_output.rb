test_name "get facts, obfuscate, and save to a local file for uploading to facterdb" do

  FACTS_OVERRIDE = {
    'dmi' => {
      'product' => {
        'serial_number' => 'VMware-99 ff ff ff ff ff ff ff-ff ff ff ff ff ff ff ff'
      }
    },
    'ssh' => {
      'dsa' => {
        'fingerprints' => {
          'sha1' => 'SSHFP 2 1 b51c7675469cb52bfa624e54bafe3ef3252f18a8',
          'sha256' => 'SSHFP 2 2 8ad3dee51616eea1922c7d0c386003564fc81a7b3c9719eda81d41fc3a1a81ce'
        },
        'key' => 'AAAAB3NzaC1kc3MAAACBAJllU17cVy4GEZpRPZq8ad2I/j6U01ymbbhtbGqlySh7bRujid3GeIDNODgwrySQWb0L8elE4QPy48zffzO55K3wysQR/sJr5SJASihkgiLN0EzYo/yDK1pyGsm9XvAmDV1y1NOkRqJud2Pg+big4t7VXHRldKffUDOr96YR1Ye9AAAAFQCSePSAGpYs3pRdqNuieYYa2Nl44QAAAIAzX0iwS3rqTOLkAl0qpgYFsd3a68dwgKK4ZixnI0L/MEB1ij1V95LHXSM18/zuwMMspkvYAMXMZQbWjvio7e7T/nh8ZMX2FUUD5tKWzkKZoCkaZK+AS/EmfUCr9C1mZF4lLK/hNKHCMUeX8dBqJyV6WvFc5UoF86OYwiNDIp7g7QAAAIAKEHm8BcZdnml4eiFTtJkgd+CYL96WlVhzYZ2sCO9iltWlcpushnOYPg95z8bIqgNR2/0Y7eB3WlxF79oJRQD4AXABqd/qAnEVmKT89EO4VHGHQrNCGfOmh+kGLJEkTrMxilLX1MABw5zUaXcSxoLDUbEOIWkYisCZzCYaZWnUYQ==',
        'type' => 'ssh-dss'
      },
      'ecdsa' => {
        'fingerprints' => {
          'sha1' => 'SSHFP 3 1 e5b5956a90381025744364c6a5e583dc241dccea',
          'sha256' => 'SSHFP 3 2 15cb5a64a36ac9e2922181a428d128d00746ff780c4d719d208f74365cee26d6'
        },
        'key' => 'AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPdGax2c3kNpf74zdu49dYPOKETTb6+2cr4Nsd+cTGXA4/gEH0nTjsBaKpQQYOHXqWCACwhoe7GmsGgpPMnVEgs=',
        'type' => 'ecdsa-sha2-nistp256'
      },
      'ed25519' => {
        'fingerprints' => {
          'sha1' => 'SSHFP 4 1 dce8023eb0e3df834f18a61c63fb47df815a5613',
          'sha256' => 'SSHFP 4 2 b4db91f2762a3e6df8e626a91deff44199069e435d4e994811f7d8845c65c4b1'
        },
        'key' => 'AAAAC3NzaC1lZDI1NTE5AAAAILn7Z73yMs5fRZLbo719JS6XB3GucAI7Z3xA7w80SVBA',
        'type' => 'ssh-ed25519'
      },
      'rsa' => {
        'fingerprints' => {
          'sha1' => 'SSHFP 1 1 8a0a9734d3d00ef801b7ff97f93360d9e53bc96b',
          'sha256' => 'SSHFP 1 2 62d70febba163aa40af1ad445c4083cce852c09ebc03216303ed8d15bd42a617'
        },
        'key' => 'AAAAB3NzaC1yc2EAAAADAQABAAABgQDGWL5DqPcs0nXR2VzOE7QAIxWKcCWihE3p2J8QYsRBYpEIBJvC2pXtmxd5SmPX7ZAAqmM0txtmzhxUsudPOhvsygGQiOuEvSZb1YrlP6G/t+Kq3VvAzS5NeQvmkL4vqXXRqfRGrgXjcv2EV7bCePgWo7Fhk6XsS7QwiCjhkiSaAOP2KeZN52dQt9g6TJnMf8ooi1liNSBjwTBpo4ACIhbuZpzEtoNnamXVOYgmGC2bhasYMgoQf8G6ArDKB+aVEz/mJu3g93vlKCrwfYAZXwXmlnyz5Wex2HBU9Cpag6ONWKrOpK/rWxgA67AhMW/DUNAG6CBUbZdTKbh0JXDCS4O9KxD4h3cBTu3/UcfV6b87KiaAZO6Ald7VLLkG3SZxOCUgDTu+Y946pt36/faVb/zX7B71wvQTHs24tVjyVWl6uh9JFUTIAW7ch34KjqzmZi21t14BoOKEqaUVoTjYWlzMumsR9GSitUB/0071lFpk0nfLKK3m913PIQPL8/se63U=',
        'type' => 'ssh-rsa'
      }
    },
    'networking' => {
      'dhcp' => '10.16.8.13',
      'ip' => '10.160.8.13',
      'ip6' => 'fe80::225f:adad:bcd0:1f75',
      'mac' => '2c:54:91:88:c9:e3',
      'network' => '10.160.8.0',
      'network6' => 'fe80::'
    },
    'hypervisors' => {
      'vmware' => { }
    }
  }

  # Recursively merge two hashes, merging the second into the first.
  # Only keys present in both hashes will be overridden by the second hash.
  #
  # Example:
  #  first = {:a=>{:b=>"c", :d=>"e"}}
  # second = {:a=>{:b=>"d", :e=>"f"}, :foo=>"bar"}
  #
  # deep_merge_if_key(first, second)  #=> {:a=>{:b=>"d", :d=>"e"}}
  def deep_merge_if_key(first, second)
    merger = proc do |key, v1, v2|
      if Hash === v1 && Hash === v2
        v2.empty? ? v2 : v1.merge(v2.select { |k| v1.keys.include?(k) }, &merger)
      elsif Array === v1 && Array === v2
        [v1, v2].flatten
                .compact
                .group_by { |v| v[:key] }
                .values
                .map { |e| e.reduce(&:merge) }
      else
        v2
      end
    end
    first.merge(second.select { |k| first.keys.include?(k) }, &merger)
  end

  # Add additional overrides to the FACTS_OVERRIDE constant, consisting of
  # legacy facts and primary network-related facts, then return the constructed
  # fact hash.
  def build_override_facts(primary_network)
    facts_override = FACTS_OVERRIDE

    facts_override['serialnumber'] = facts_override['dmi']['product']['serial_number']
    ['dsa', 'ecdsa', 'ed25519', 'rsa'].each do |key|
      facts_override["ssh#{key}key"] = facts_override['ssh'][key]['key']

      facts_override["sshfp_#{key}"] = facts_override['ssh'][key]['fingerprints']['sha1'] + "\n" + facts_override['ssh'][key]['fingerprints']['sha256']

    end

    facts_override['networking']['interfaces'] = {}
    facts_override['networking']['interfaces'][primary_network] = facts_override['networking']
    facts_override['networking']['interfaces'][primary_network]['bindings'] = [{}]
    facts_override['networking']['interfaces'][primary_network]['bindings'].first['address'] = facts_override['networking']['ip']
    facts_override['networking']['interfaces'][primary_network]['bindings'].first['network'] = facts_override['networking']['network']

    facts_override['networking']['interfaces'][primary_network]['bindings6'] = [{}]
    facts_override['networking']['interfaces'][primary_network]['bindings6'].first['address'] = facts_override['networking']['ip6']
    facts_override['networking']['interfaces'][primary_network]['bindings6'].first['network'] = facts_override['networking']['network6']

    facts_override['ipaddress'] = facts_override['networking']['ip']
    facts_override['ipaddress6'] = facts_override['networking']['ip6']
    facts_override["ipaddress_#{primary_network}"] = facts_override['networking']['ip']
    facts_override["ipaddress6_#{primary_network}"] = facts_override['networking']['ip6']
    facts_override['macaddress'] = facts_override['networking']['mac']
    facts_override["macaddress_#{primary_network}"] = facts_override['networking']['mac']
    facts_override['network'] = facts_override['networking']['network']
    facts_override["network_#{primary_network}"] = facts_override['networking']['network']
    facts_override["network6_#{primary_network}"] = facts_override['networking']['network6']

    facts_override['dhcp_servers'] = {}
    facts_override['dhcp_servers'][primary_network] = facts_override['networking']['dhcp']
    facts_override['dhcp_servers']['system'] = facts_override['networking']['dhcp']

    facts_override
  end

  # Given a fact hash, return a facterdb-compliant filepath.
  #
  # Example: 4.2.6/centos-8-x86_64.facts
  def filename_from_facts(facts)
    facterversion = facts['facterversion']
    osname = facts['operatingsystem'].downcase
    osrelease = facts['operatingsystemmajrelease']
    arch = facts['hardwaremodel']

    File.join(facterversion, "#{osname}-#{osrelease}-#{arch}.facts")
  end

  agents.each do |agent|
    on(agent, facter('--show-legacy -p -j'), :acceptable_exit_codes => [0]) do |result|
      facts = JSON.parse(result.stdout)
      facter_major_version = facts['facterversion']
      primary_network = facts['networking']['primary']

      override_facts = build_override_facts(primary_network)

      final_facts = deep_merge_if_key(facts, override_facts)

      # save locally
      file_path = File.expand_path(File.join('output', 'facts', filename_from_facts(final_facts)))
      FileUtils.mkdir_p(File.dirname(file_path))

      File.write(file_path, JSON.pretty_generate(final_facts))
    end
  end
end
