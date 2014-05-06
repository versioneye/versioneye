set :stage, :staging

set :rails_env   , :staging

set :normalize_asset_timestamps, %{public/images public/javascripts public/stylesheets}

role :app, %w{ubuntu@veye_staging}

set :ssh_options, {
 forward_agent: true # , auth_methods: %w(password)
}
