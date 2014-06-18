# Load the rails application
require File.expand_path('../application', __FILE__)


Versioneye::Application.initialize!

es_url = Settings.instance.elasticsearch_url
if !Settings.instance.elasticsearch_addr.to_s.empty? && !Settings.instance.elasticsearch_port.to_s.empty?
  es_url = "#{Settings.instance.elasticsearch_addr}:#{Settings.instance.elasticsearch_port}"
end

begin
  Tire.configure do
    # logger STDOUT
    # logger STDERR
    url es_url
  end
rescue => e
  Rails.logger.error "Wrong configuration: #{e}"
end
