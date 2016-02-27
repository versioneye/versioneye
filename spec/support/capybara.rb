require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/firebug'

Capybara.app_host = 'http://localhost:3000'
Capybara.server_host = 'localhost'
Capybara.server_port = '3000'

Capybara.register_driver :selenium_firefox_driver do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => profile)
end
