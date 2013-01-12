if Rails.env.development?
  lib_reloader = ActiveSupport::FileUpdateChecker.new(Dir["app/api/**/*"]) do
    Rails.application.reload_routes!
  end

  ActionDispatch::Callbacks.to_prepare do
    lib_reloader.execute_if_updated
  end
end