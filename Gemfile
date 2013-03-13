source 'http://rubygems.org'
ruby "1.9.3"

gem 'rails', '3.2.12'
gem 'jquery-rails', '2.2.0'
gem 'execjs', '1.4.0'
gem 'will_paginate', '3.0.4'
gem 'gravatar_image_tag', '1.1.3'
gem 'bson_ext', '1.7.0'
gem 'mongo', '1.7.0'
gem 'mongoid', '2.5.0'
gem 'naturalsorter', '1.0.1'
gem 'postmark-rails', '0.4.1'
gem 'httparty', '0.10.2'
gem 'oauth', '0.4.7'
gem 'twitter_oauth', '0.4.4'
gem 'aws-s3', '0.6.3', :require => 'aws/s3'
gem 'nokogiri', '1.5.6'
gem 'stripe', '1.7.10'
gem 'thin', '1.4.1'
gem 'tire', '0.5.4'
# gem 'yajl-ruby', '1.1.0'     # another JSON parser
gem 'json', '1.7.7'
gem 'dalli', '2.6.2'           # memcache library
gem 'kgio', '2.8.0'            # 20% performance boost for dalli
gem 'grape' 
gem 'grape-entity'
gem 'grape-swagger', git: "https://github.com/timgluz/grape-swagger.git" 
#, :git => 'https://github.com/tim-vandecasteele/grape-swagger.git'
gem 'htmlentities'

group :development do
  gem 'libv8' , '~> 3.11.8'
  gem 'therubyracer' #, '0.11.1', :platforms => :ruby, :require => 'v8'
  gem 'psych'
  gem 'irbtools'
  gem 'terminal-notifier'
  gem 'fakes3'
end

group :assets do
  gem 'sass', :require => 'sass'
  gem 'sass-rails', "3.2.6"
  gem 'coffee-rails', "3.2.2"
  gem 'uglifier'
  gem 'yui-compressor', '0.9.6'
end

group :test do
  gem 'turn', :require => false
  gem "rspec-rails", "~> 2.0"
  gem 'webrat', '0.7.3'
end
