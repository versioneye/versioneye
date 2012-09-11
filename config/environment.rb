# Load the rails application
require File.expand_path('../application', __FILE__)


class Settings
	raw_config = File.read("#{::Rails.root.to_s}/config/config.yml")
	erb_config = ERB.new(raw_config).result
	settings = YAML.load(erb_config)[::Rails.env]
    
	if settings
		settings.each { |name, value|
			instance_variable_set("@#{name}", value)
			self.class.class_eval { attr_reader name.intern }
		}
	end
end


Versioneye::Application.initialize!

if Settings.aws_s3_access_key_id && Settings.aws_s3_secret_access_key
	AWS::S3::Base.establish_connection!(
	  :access_key_id     => Settings.aws_s3_access_key_id,
	  :secret_access_key => Settings.aws_s3_secret_access_key
	)
end

#ENV['RAILS_ENV'] = 'development'

# ENV["RAILS_RELATIVE_URL_ROOT"] = "versioneye.com"
