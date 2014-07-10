namespace :versioneye do

  desc "execute the daily jobs"
  task :daily_jobs => :environment do
    puts "START to update Indexes."
    begin
      Indexer.create_indexes
    rescue => e
      p e.message
      p e.backtrace.join("\n")
    end
    puts "---"

    puts "START to update the json strings for the statistic page."
    StatisticService.update_all
    puts "---"

    puts "START to update integration status of submitted urls"
    SubmittedUrlService.update_integration_statuses()
    puts "---"

    puts "START update meta data on products. Update followers, version and used_by_count"
    ProductService.update_meta_data_global
    puts "---"

    puts "START reindex newest products for elastic search"
    EsProduct.index_newest
    puts "---"

    puts "START reindex users for elastic search"
    EsUser.reset
    EsUser.index_all
    puts "---"

    puts "START to send out the notification E-Mails."
    NotificationService.send_notifications
    puts "---"

    puts "START to send out daily project notification E-Mails."
    ProjectUpdateService.update_all( Project::A_PERIOD_DAILY )
    puts "---"

    puts "START to LanguageDailyStats.update_counts"
    LanguageDailyStats.update_counts(3, 1)
    puts "---"

    puts "START to update all github repos"
    GitHubService.update_all_repos
    puts "---"

    puts "START to update all user languages"
    UserService.update_languages
    puts "---"

    puts "START to send out receipts "
    ReceiptService.process_receipts
    puts "---"
  end

  desc "excute weekly jobs"
  task :weekly_jobs => :environment do
    puts "START to send out weekly project notification E-Mails."
    ProjectUpdateService.update_all( Project::A_PERIOD_WEEKLY )
    puts "---"

    puts "START to send out verification reminder E-Mails."
    User.send_verification_reminders
    puts "---"
  end

  desc "excute monthly jobs"
  task :monthly_jobs => :environment do
    puts "START to send out monthly project notification emails."
    ProjectUpdateService.update_all( Project::A_PERIOD_MONTHLY )
    puts "---"
  end


  # ***** Email Tasks *****

  desc "send out new version email notifications"
  task :send_notifications => :environment do
    puts "START to send out the notification E-Mails."
    NotificationService.send_notifications
    puts "---"
  end

  desc "send out verification reminders"
  task :send_verification_reminders => :environment do
    puts "START to send out verification reminder E-Mails."
    User.send_verification_reminders
    puts "---"
  end

  desc "send out suggestion emails to inactive users"
  task :send_suggestions do
    puts "START to send out suggestion emails to inactive users"
    User.non_followers.each { |user| user.send_suggestions }
    puts "STOP  to send out suggestion emails to inactive users"
  end


  # ***** XML Sitemap Tasks *****

  desc "create XML site map"
  task :xml_sitemap => :environment do
    puts "START to export xml site map"
    ProductMigration.xml_site_map
    puts "---"
  end

  # ***** Admin tasks *****

  desc "create default admin"
  task :init_enterprise => :environment do
    puts "START to create default admin"
    AdminService.create_default_admin
    Plan.create_defaults
    EsProduct.reset
    EsUser.reset
    puts "---"
  end

  # ***** Crawler Tasks *****

  desc "crawl Packagist"
  task :crawl_packagist => :environment do
    puts "START to crawle Packagist repository"
    PackagistCrawler.crawl
    puts "---"
  end

  desc "crawl Tiki"
  task :crawl_tiki => :environment do
    puts "START to crawle Tiki repository"
    TikiCrawler.crawl
    puts "---"
  end

  desc "crawl NPM"
  task :crawl_npm => :environment do
    puts "START to crawle NPM repository"
    NpmCrawler.crawl
    puts "---"
  end

  desc "crawl Cococapods"
  task :crawl_cocoapods => :environment do
    puts "START to crawle CocoaPods repository"
    CocoapodsCrawler.crawl
    GithubVersionCrawler.crawl
    puts "---"
  end

  desc "crawl GitHub"
  task :crawl_github => :environment do
    puts "START to crawle GitHub repository"
    GithubCrawler.crawl
    puts "---"
  end

  desc "crawl Bower.io"
  task :crawl_bower => :environment do
    puts "START to crawle Bower.io repository"
    reiz = User.find_by_username('reiz')
    BowerCrawler.crawl reiz.github_token
    puts "---"
  end

end
