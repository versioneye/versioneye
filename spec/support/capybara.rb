require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/firebug'

Capybara.app_host = 'http://localhost:3000'
Capybara.server_host = 'localhost'
Capybara.server_port = '3000'

# Capybara.register_driver :selenium_firefox_driver do |app|
#   profile = Selenium::WebDriver::Firefox::Profile.new
#   driver = Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => profile)
#   driver.manage.window.resize_to(1000, 1000)
# end

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app,
    browser: :chrome,
    desired_capabilities: {
      "chromeOptions" => {
        "args" => %w{ window-size=1024,768 }
      }
    }
  )
end
