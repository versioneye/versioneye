module ApplicationHelper

  def url_abs( url )
    return url if url.to_s.match(/\Ahttp/i)
    "http://#{url}"
  end

  def title( page_title )
    content_for(:title){ page_title }
  end

  def page_header( page_header )
    content_for(:page_header){ page_header }
  end

  def github_enabled?
    !Settings.instance.github_base_url.to_s.empty? &&
    !Settings.instance.github_api_url.to_s.empty? &&
    !Settings.instance.github_client_id.to_s.empty? &&
    !Settings.instance.github_client_secret.to_s.empty?
  rescue => e
    false
  end

  def bitbucket_enabled?
    !Settings.instance.bitbucket_token.to_s.empty? &&
    !Settings.instance.bitbucket_secret.to_s.empty?
  rescue => e
    false
  end

  def stash_enabled?
    !Settings.instance.stash_base_url.to_s.empty? &&
    !Settings.instance.stash_consumer_key.to_s.empty? &&
    !Settings.instance.stash_private_rsa.to_s.empty?
  rescue => e
    false
  end

  def social_logins_enabled?
    github_enabled? || bitbucket_enabled? || stash_enabled?
  end

end
