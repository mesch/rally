source 'http://rubygems.org'

gem 'rails', '3.0.0'
gem 'mysql'
gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'ruby-debug'

gem 'compass', ">=0.10.6"
gem 'delayed_job'
gem 'koala'
gem 'money'
gem 'xml-simple'
gem 'paperclip'

gem 'aws-s3', :require => 'aws/s3'
gem 'right_aws'

gem 'nokogiri'
gem 'authorize-net', "1.5.2", :path => 'vendor/gems/authorize-net-1.5.2'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test, :staging do
	gem 'launchy'
	gem 'builder', '~> 2.1.2'
	gem 'rspec'
	gem 'rspec-rails'
	gem 'capybara'
	gem 'database_cleaner'
	gem 'cucumber-rails'
end

group :development do
  gem 'rails-erd'
end
