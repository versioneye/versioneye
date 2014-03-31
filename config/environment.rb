# Load the rails application
require File.expand_path('../application', __FILE__)


Versioneye::Application.initialize!


begin
  Tire.configure do
    # logger STDOUT
    # logger STDERR
    url Settings.elasticsearch_url
  end
rescue => e
  Rails.logger.error "Wrong configuration: #{e}"
end
