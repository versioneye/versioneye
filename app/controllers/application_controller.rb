class ApplicationController < ActionController::Base

  protect_from_forgery

  include SessionsHelper
  include ProductsHelper
  include UsersHelper
  include ProjectsHelper
  include RefersHelper

  after_filter :disconnect

  # Explicitly close the connection to MongoDB.
  # This is a bug in MongoID 3.X.
  # http://grokbase.com/t/gg/mongoid/129cezk75h/no-of-connections-to-mongo-not-closing
  #
  def disconnect
    Mongoid.default_session.disconnect
  rescue => e
    p e.message
    Rails.logger.error e.message
    Rails.logger.error e.stacktrace.join "\n"
  end

end
