set :stage, :test

set :rails_env   , :test

set :normalize_asset_timestamps, %{public/images public/javascripts public/stylesheets}

role :app, %w{ubuntu@10.0.2.15}

set :ssh_options, {
 forward_agent: true # , auth_methods: %w(password)
}
