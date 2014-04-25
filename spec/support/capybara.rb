require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/firebug'

Capybara.app_host = 'http://localhost:3000'
Capybara.server_host = 'localhost'
Capybara.server_port = '3000'
