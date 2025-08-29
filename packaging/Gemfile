source ENV['GEM_SOURCE'] || "https://rubygems.org"

def location_for(place)
  if place =~ /^((?:git[:@]|https:)[^#]*)#(.*)/
    [{ :git => $1, :branch => $2, :require => false }]
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

gem 'vanagon', *location_for(ENV['VANAGON_LOCATION'] || 'https://github.com/openvoxproject/vanagon#main')
gem 'packaging', *location_for(ENV['PACKAGING_LOCATION'] || '~> 0.105')
gem 'artifactory'
gem 'rake'
gem 'json'
gem 'octokit'
gem 'rubocop', "~> 1.22"
gem 'rubocop-rake'

group :release, optional: true do
  gem 'faraday-retry', require: false
  gem 'github_changelog_generator', git: 'https://github.com/smortex/github-changelog-generator.git', branch: 'avoid-processing-a-single-commit-multiple-time', require: false
end
