RSpec.configure do |config|

  config.include RSpec::Rails::RequestExampleGroup,
                :type => :request,
                :example_group => { :file_path => /spec\/api\/v1/ }

end
