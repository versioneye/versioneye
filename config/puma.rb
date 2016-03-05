port 8080
threads 1,8
workers 3
# preload_app!

on_worker_boot do
  # ActiveSupport.on_load(:active_record) do
  #   ActiveRecord::Base.establish_connection
  # end
end
