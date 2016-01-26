
RSpec.configure do |config|

  config.before(:each) do
    Rails.application.eager_load!
    models = Mongoid.models
    models.each do |model|
      model.all.each(&:delete)
    end
  end

end
