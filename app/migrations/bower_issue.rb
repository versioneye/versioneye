class BowerIssue

  def self.logger
    ActiveSupport::BufferedLogger.new('log/bower_issue.log')
  end

  def self.crawl_tags
    version_tasks = CrawlerTask.where(task: BowerCrawler::A_TASK_READ_VERSIONS)
    user = User.find_by_username("reiz")
    token = user.github_token

    producer = Thread.new do
      version_tasks.each {|task| create_tag_task(task, token)}
      sleep 1/100.0
    end

    worker = Thread.new do
      BowerCrawler.crawl_tag_project(token)
    end

    producer.join
    worker.join

    logger.debug "crawl_tags is done."
  end

  def self.create_tag_task(task, token)
    BowerCrawler.check_request_limit(token)
    tags = Github.repo_tags(task[:repo_fullname], token)
    if tags.nil? || tags.empty?
      logger.warn "`#{task[:repo_fullname]}` has no versions - going to skip."
      return
    end

    tags.each {|tag| BowerCrawler.to_tag_project_task(task, tag)}
  end

  def self.count_empty_tags(token)
    if token.nil?
      reiz = User.find_by_username("reiz")
      token = reiz.github_token
    end
    count = 0
    prod_keys = Product.collection.find({'versions.2' => {'$exists' => false}, 'prod_type' => 'Bower'}).distinct(:prod_key)
    prod_keys.each do |prod_key|
      prod = Product.where(:prod_type => "Bower", :prod_key => prod_key ).first
      links         = prod.http_links
      version_links = prod.http_version_links
      merged_links  = links.concat(version_links)
      link_set = Set.new
      merged_links.each do |link|
        if link.link.match(/http\:\/\/github\.com/).nil?
          next
        end
        link_set << link.link
      end
      link_set.each do |link|
        repo_info = BowerCrawler.url_to_repo_info(link)
        if repo_info.nil?
          p " -- try the next link"
          next
        end
        tags = Github.repo_tags(repo_info[:full_name], token)
        if tags.nil? || tags.empty?
          count += 1
          p "#{prod.prod_key} - #{link} - #{count}"
          next
        end
      end
    end
  end

  def self.post_for_repo(repo_fullname, token)
    title = "[enhancement] Add missing bower.json."
    template_path = '/app/views/bower_mailer/missing_project_file_issue.md.erb'

    github = Octokit::Client.new(access_token: token)
    issue_template = File.open("#{File.absolute_path('.')}#{template_path}").read
    render = ERB.new(issue_template)

    @repo_fullname = repo_fullname
    content = render.result binding
    github.create_issue(repo_fullname, title, content).attrs.to_hash
  end

  def self.post_for_missing_project_files(token)
    missing_repos = CrawlerTask.by_task(BowerCrawler::A_TASK_READ_PROJECT).where(task_failed: true)
    success = 0
    failed =  0
    missing_repos.each do |task|
      begin
        post_for_repo(task[:repo_fullname], token)
        logger.info "#{task[:repo_fullname]} success."
        success += 1
        sleep 1/10.0
      rescue => e
        logger.info "#{task[:repo_fullname]} failed: #{e.message}"
        failed += 1
      end
    end
    return {success: success, failed: failed}
  end

  def self.close_issues(token)
    opened_issues = Github.get_json("#{Github:A_API_URL}/issues", token)
    opened_issues.to_a.each do |issue|
      if issue[:state] == "open" and issue[:creator][:login] = "timgluz"
        close_issue(issue, token)
      end
    end
  end


  def self.close_issue(issue, token)

  end
end
