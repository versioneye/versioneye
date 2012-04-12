class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ProductsHelper
  include UsersHelper  
  include ProjectsHelper

  def client
    Twitter.configure do |config|
      config.consumer_key = ENV['XCXPzp6GGZcFfCw2UhxocA']
      config.consumer_secret = ENV['so1T6l4nrLaY5IZEfIFzb8CtkrmNwe0I7K6F4a3oZx4']
      config.oauth_token = session['459276601-yeQVidGx9MsmNHvBYnUrjlusoLfJ17ti86m3H6vP']
      config.oauth_token_secret = session['g7QEZT31SvM3mCEwYWzqfMXjsMRWwMnbdwhbZOGb8']
    end
    @client ||= Twitter::Client.new
  end
  
end
