namespace :versioneye do

  desc "execute the daily jobs"
  task :daily_jobs => :environment do
    puts "START to update the json strings for the statistic page."
    StatisticService.update_all
    puts "END to update the json strings for the statistic page."

    puts "START to update integration status of submitted urls"
    SubmittedUrl.update_integration_statuses()
    puts "STOP  to update integration status of submitted urls"

    puts "START to crawl packagist.org"
    PackagistCrawler.crawl
    puts "STOP to crawl packagist.org"

    puts "START update meta data on products. Update followers, version and used_by_count"
    ProductMigration.update_meta_data_global
    puts "STOP  update meta data on products."

    puts "START reindex newest products for elastic search"
    EsProduct.index_newest
    puts "STOP reindex newest products for elastic search"

    puts "START reindex users for elastic search"
    EsUser.reset
    EsUser.index_all
    puts "STOP reindex uses for elastic search"

    puts "START to send out the notification E-Mails."
    Notification.send_notifications
    puts "STOP to send out the notification E-Mails."

    puts "START to send out daily project notification E-Mails."
    ProjectService.update_all( Project::A_PERIOD_DAILY )
    puts "STOP to send out daily project notification E-Mails."

    puts "START to LanguageDailyStats.update_counts"
    LanguageDailyStats.update_counts(3, 1)
    puts "STOP to LanguageDailyStats.update_counts"
  end

  desc "excute weekly jobs"
  task :weekly_jobs => :environment do
    puts "START to send out weekly project notification E-Mails."
    ProjectService.update_all( Project::A_PERIOD_WEEKLY )
    puts "STOP to send out weekly project notification E-Mails."
  end

  desc "excute monthly jobs"
  task :monthly_jobs => :environment do
    puts "START to send out monthly project notification emails."
    ProjectService.update_all( Project::A_PERIOD_MONTHLY )
    puts "STOP to send out monthly project notification emails."
  end

  desc "update version data globally"
  task :update_version_data_global => :environment do
  puts "START update the version numbers on products."
    ProductMigration.update_version_data_global
    puts "STOP update the version numbers on products."
  end

  desc "send out new version email notifications"
  task :send_notifications => :environment do
    puts "START to send out the notification E-Mails."
    Notification.send_notifications
    puts "STOP to send out the notification E-Mails."
  end

  desc "send out verification reminders"
  task :send_verification_reminders => :environment do
    puts "START to send out verification reminder E-Mails."
    User.send_verification_reminders
    puts "STOP to send out verification reminder E-Mails."
  end

  desc "crawl & import Cococapods specs"
  task :crawl_cocoapods => :environment do
    CocoapodsCrawler.crawl
  end
end
