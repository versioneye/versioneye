require 'dalli'

module CacheHelpers
  @@default_cache_options = {
    namespace: 'api2',
    expires_in: 300,
  }

  def init_cache(opts = nil)
    if opts.is_a?(Hash)
      opts = @@default_cache_options.merge(opts)
    else
      opts = @@default_cache_options
    end

    @@cache_client = Dalli::Client.new('localhost:11211', opts)
  end
  def get_cache(cache_key)
    init_cache({}) unless @@cache_client
    @@cache_client.get(cache_key)
  end

  def set_cache(cache_key, val)
    init_cache({}) unless @@cache_client
    @@cache_client.get(cache_key, val)
  end
end