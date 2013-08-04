# Automatically precompile assets
load "deploy/assets"

# Execute "bundle install" after deploy, but only when really needed
require "bundler/capistrano"

set :application, "versioneye"
set :repository , "git@github.com:versioneye/versioneye.git"

set :scm, :git

set :ssh_options, {:forward_agent => true}

set :deploy_to, "/var/www/versioneye"

role :web, "yunicon_app"                      # Your HTTP server, Apache/etc
role :app, "yunicon_app"                      # This may be the same as your `Web` server
role :db,  "yunicon_app", :primary => true    # This is where Rails migrations will run

set :rails_env, :production

set :user, "versioneye"
set :use_sudo, false

namespace :deploy do

  task :start, :roles => :app, :except => { :no_release => true } do
    run "/etc/init.d/unicorn start"
  end

  task :stop, :roles => :app, :except => { :no_release => true } do
    run "/etc/init.d/unicorn stop"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "/etc/init.d/unicorn restart"
  end

  # Precompile assets
  namespace :assets do
    task :precompile, :roles => :web, :except => { :no_release => true } do
      run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
    end
  end

end
