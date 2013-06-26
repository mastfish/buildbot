# If you need to 'vendor your gems' for deploying your daemons, bundler is a
# great option. Update this Gemfile with any additional dependencies and run
# 'bundle install' to get them all installed. Daemon-kit's capistrano
# deployment will ensure that the bundle required by your daemon is properly
# installed.
#
# For more information on bundler, please visit http://gembundler.com

source 'https://rubygems.org'
ruby '2.0.0'

# daemon-kit
gem 'daemon-kit'
gem 'sqlite3'
gem 'rest-client'
gem 'github_api'

# safely (http://github.com/kennethkalmer/safely)
gem 'safely'
# gem 'toadhopper' # For reporting exceptions to hoptoad
# gem 'mail' # For reporting exceptions via mail
gem 'rufus-scheduler', '>= 2.0.3'
group :development, :test do
  gem 'pry'
  gem 'rake'
  gem 'rspec'
end