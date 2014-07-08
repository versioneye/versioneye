
set :stage, :production

set :rails_env, :production

set :normalize_asset_timestamps, %{public/images public/javascripts public/stylesheets}

role :app, %w{ubuntu@54.72.33.230}

set :ssh_options, {
   forward_agent: true # , auth_methods: %w(password)
}
