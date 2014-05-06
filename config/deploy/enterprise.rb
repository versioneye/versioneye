
set :stage, :enterprise

set :rails_env, :enterprise

set :normalize_asset_timestamps, %{public/images public/javascripts public/stylesheets}

role :app, %w{ubuntu@veye_enterprise}

set :ssh_options, {
   forward_agent: true # , auth_methods: %w(password)
}
