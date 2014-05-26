require 'fakeweb'

RSpec.configure do |config|

  config.before(:each) do
    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry
  end

end
