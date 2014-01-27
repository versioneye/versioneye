class BowerIssue

  def self.logger
    ActiveSupport::BufferedLogger.new('log/bower_issue.log')
  end

  def self.count_empty_tags(token)
    count = 0
    Product.collection.find({'versions.1' => {'$exists' => false}, 'prod_type' => 'Bower'}).each do |pr|
      prod_key = pr['prod_key']
      prod = Product.where(:prod_type => "Bower", :prod_key => prod_key ).first
      links         = prod.http_links
      version_links = prod.http_version_links
      merged_links  = links.concat(version_links)
      merged_links.each do |link|
        if link.link.match(/github\.com/).nil?
          next
        end
        repo_info = BowerCrawler.url_to_repo_info(link.link)
        if repo_info.nil?
          p " -- try the next link"
          next
        end
        tags = Github.repo_tags(repo_info[:full_name], token)
        if tags.nil? || tags.empty?
          count += 1
          p "#{prod.prod_key} - #{link.link} - #{count}"
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
