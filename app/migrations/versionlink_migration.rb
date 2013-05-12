class VersionlinkMigration

  def self.run_all_converts
    self.convert_git_to_https
    self.convert_www_to_http
    self.convert_githubcom_to_http
    self.convert_git_at_githubcom_to_http
  end

  def self.convert_git_to_https
    links = Versionlink.all(conditions: {link: /^git:\/\/github.com.*.git$/ })
    links.each do |link| 
      new_link = link.link.gsub("git://github.com", "https://github.com").gsub(".git", "")
      save_new_link link, new_link  
    end
  end

  def self.convert_www_to_http
    links = Versionlink.all(conditions: {link: /^www.*/ })
    links.each do |link| 
      new_link = "http://#{link.link}"
      save_new_link link, new_link
    end
  end

  def self.convert_githubcom_to_http
    links = Versionlink.all(conditions: {link: /^github.com*/ })
    links.each do |link| 
      new_link = "http://#{link.link}"
      save_new_link link, new_link
    end
  end

  def self.convert_git_at_githubcom_to_http
    links = Versionlink.all(conditions: {link: /^git\@github.com*/ })
    links.each do |link| 
      new_link = link.link.gsub("git@github.com:", "https://github.com/").gsub(".git", "")
      save_new_link link, new_link
    end
  end

  private 

    def self.save_new_link link, new_link
      new_link_is_valid = self.link_ok? new_link
      if new_link_is_valid
        resp = Versionlink.create_versionlink link.prod_key, link.version_id, new_link, link.name
        if !resp.nil? 
          Rails.logger.info "added: #{new_link} - #{link.prod_key} - #{link.version_id}" 
        end
      end 
    end

    def self.link_ok? link
      url = URI.parse( link )
      req = Net::HTTP.new(url.host, url.port)
      req.use_ssl = true
      req.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = req.request_head(url.path)
      res.code.to_i == 200
    rescue => e 
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.first
      return false 
    end 

end 