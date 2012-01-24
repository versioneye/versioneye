Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV['CONSUMER_KEY'].blank? || ENV['CONSUMER_SECRET'].blank?
    provider :twitter, ENV['XCXPzp6GGZcFfCw2UhxocA'], ENV['so1T6l4nrLaY5IZEfIFzb8CtkrmNwe0I7K6F4a3oZx4']
  else
    provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
  end
end