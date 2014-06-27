require 'database_cleaner'

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
    Indexer.drop_indexes
    Indexer.create_indexes
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end

end
