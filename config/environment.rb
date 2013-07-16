# Load the rails application
require File.expand_path('../application', __FILE__)


Versioneye::Application.initialize!


begin
	Tire.configure do
		# logger STDERR
		url Settings.elasticsearch_url
	end
rescue => e
	p "Wrong configuration: #{e}"
end

