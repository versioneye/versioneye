
set :stage, :production

set :rails_env, :production

set :normalize_asset_timestamps, %{public/images public/javascripts public/stylesheets}

role :app, %w{ubuntu@veye_app_1}

set :ssh_options, {
   forward_agent: true # , auth_methods: %w(password)
}
