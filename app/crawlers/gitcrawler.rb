class GitCrawler

  def initialize url, dir
    @url = url
    @dir = dir
  end

  def clone
    `git clone #{url} #{dir}`
  end

  alias_method :setup, :clone

  def pull
    `(cd #{dir} && git pull)`
  end

  alias_method :update, :pull
end