class GitCrawler

  def initialize git_url, dir
    @git_url, @dir = git_url, dir
  end

  def run cmd_string
    Rails.logger.info "Running: $ #{cmd_string}"
    `#{cmd_string}`
  end

  def clone
    p "git clone #{@git_url} #{@dir}"
    run "git clone #{@git_url} #{@dir}"
  end

  alias_method :setup, :clone

  def pull
    p "(cd #{@dir} && git pull)"
    run "(cd #{@dir} && git pull)"
  end

  alias_method :update, :pull

end
