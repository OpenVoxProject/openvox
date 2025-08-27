# Tests

Puppet Agent uses [beaker](github.com/puppetlabs/beaker) for running acceptance tests

## Running Tests

Acceptance tests are triggered using `rake acceptance`

### Usage
```
# cd acceptance
# bundle install --path .bundle
# bundle exec rake <command> ENVIRONMENT_VARIABLE=value
```

#### Example Invocations
* print listing and explanation of useful environment variables
```
bundle exec rake help
```

* print listing of available rake tasks
```
bundle exec rake -T
```

* run tests against puppet agent 1.7.0 on agent platform windows
2016 x64, downloaded from builds.delivery.puppetlabs.net
```
bundle exec rake acceptance:development SHA='1.7.0' TEST_TARGET=windows2016-64a
``` 

* run tests against the latest nightly build of puppet agent on the public
nightlies build server, using the default platform for agent and server.
```
bundle exec rake acceptance:development SHA='latest' AGENT_DOWNLOAD_URL='http://nightlies.puppet.com'
``` 

 * run tests against the released 1.8.0 puppet agent packages on our production
 repos (ie yum.puppet.com) on the ubuntu 16.04 64-bit platform
```
bundle exec rake acceptance:released SHA='1.8.0' TEST_TARGET=ubuntu1604-64a
```

### Settings and Environment Variables
* SHA=sha (required)
> Supply git ref (sha or tag) of packages of this repository to be put under test.
> Also supports the literal string 'latest' which references the latest
> build on http://nightlies.puppet.com.
> If setting SHA to 'latest', you must also set ENV['AGENT_DOWNLOAD_URL'] to
> http://nightlies.puppet.com.

* BEAKER_HOSTS=config/nodes/foo.yaml
> Supply the path to a yaml file in the format of a beaker hosts file containing
> the test targets, roles, etc., or specify it in a beaker options.rb file.

* TEST_TARGET='beaker-hostgenerator target'
> Supply a test target in the form beaker-hostgenerator accepts, e.g.
> ubuntu1504-64a. Defaults to a constant defined in [Rakefile](Rakefile).
 
* AGENT_DOWNLOAD_URL='http://example.com'
> Supply the url of the host serving packages of puppet agent to test matching
> `SHA`. Ignored by `rake acceptance:released` which always uses the production
> Puppet repository urls.
>
> Valid values are:
> * http://builds.delivery.puppetlabs.net (Puppet internal builds)
> * http://nightlies.puppet.com (Puppet public nightly builds)
> 
> Default: http://builds.delivery.puppetlabs.net.
 
* TESTS='path/to/test,and/more/tests'
> Supply a comma-separated string (no spaces) of specific test(s) to run.
> All pre-suites will be run, unless a specific pre-suite file is supplied as the
> value to this option, in which case test exercise will terminate after the
> supplied pre-suite file. Relative to 'acceptance' directory.
>
> Example: TESTS='tests/ensure_version_file.rb'

* OPTIONS='--more --options'
> Supply additional options to pass to the beaker invocation
>
> Example: OPTIONS='--preserve-hosts=never'

If there is a Beaker options hash in a ./local_options.rb, it will be included.
Commandline options set through the above environment variables will override
settings in this file.

### Caveats
Running acceptance tests requires packages of the test target SHA have already
been built and exist on a download server that beaker can install from. The two
most commonly used download urls are http://nightlies.delivery.puppet.net
(public) and http://builds.delivery.puppetlabs.net.

TODO A future version of acceptance tests will support building packages of a
given SHA locally and then running acceptance tests against those packages.

Spec Tests
---
Puppet Agent does not currently have spec tests
