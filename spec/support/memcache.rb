require 'database_cleaner'

RSpec.configure do |config|

  config.before(:each) do
    Rails.cache.clear
  end

end
