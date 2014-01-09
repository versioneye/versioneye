
SSHKit.config.command_map[:rake] = "bundle exec rake"

set :application, 'versioneye'

set :scm     , :git
set :repo_url, 'git@github.com:versioneye/versioneye.git'
set :branch  , "master"

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

  # desc 'assets:precompile'
  # namespace :assets do
  #   task :precompile do
  #     on roles :app, in: :sequence, wait: 5 do
  #       within release_path do
  #         with rails_env: fetch(:rails_env) do
  #           execute :rake, "assets:precompile"
  #         end
  #       end
  #     end
  #   end
  # end

  after :finishing, 'deploy:cleanup'

end
