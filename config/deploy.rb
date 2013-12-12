
set :application, 'versioneye'

set :scm     , :git
set :repo_url, 'git@github.com:versioneye/versioneye.git'
set :branch  , "ruby_2"

set :ssh_options, {:forward_agent => true}
set :user       , "ubuntu"
set :use_sudo   , false
set :deploy_to  , '/var/www/versioneye'

set :format   , :pretty
set :log_level, :info # :debug :error

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :keep_releases, 7

desc "Check that we can access everything"
task :check_write_permissions do
  on roles(:all) do |host|
    if test("[ -w #{fetch(:deploy_to)} ]")
      info "#{fetch(:deploy_to)} is writable on #{host}"
    else
      error "#{fetch(:deploy_to)} is not writable on #{host}"
    end
  end
end

namespace :deploy do

  desc 'Start application'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute "/etc/init.d/unicorn start"
    end
  end

  desc 'Stop application'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute "/etc/init.d/unicorn stop"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      ["log", "pids"].each do |path|
        execute "ln -fs #{shared_path}/#{path} #{release_path}/#{path}"
      end
      execute "/etc/init.d/unicorn restart"
    end
  end

  # Precompile assets
  # namespace :assets do

  #   desc 'Precompile all assets'
  #   task :precompile, :roles => :app, :except => { :no_release => true } do
  #     run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
  #   end

  # end

  # desc 'Restart application'
  # task :restart do
  #   on roles(:app), in: :sequence, wait: 5 do
  #     # Your restart mechanism here, for example:
  #     # execute :touch, release_path.join('tmp/restart.txt')
  #   end
  # end

  # after :restart, :clear_cache do
  #   on roles(:web), in: :groups, limit: 3, wait: 10 do
  #     # Here we can do anything such as:
  #     # within release_path do
  #     #   execute :rake, 'cache:clear'
  #     # end
  #   end
  # end

  after :finishing, 'deploy:cleanup'

end
