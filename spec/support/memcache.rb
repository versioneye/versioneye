require 'database_cleaner'

RSpec.configure do |config|

  config.before(:suite) do
    Rails.cache.clear
  end

end
