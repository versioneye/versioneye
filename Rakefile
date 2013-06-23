#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Versioneye::Application.load_tasks

task :do_work => :environment do
	puts "START"

	start_hour = 2
	start_minute = 10

	weekly_hour = 15
	weekly_minute = 00
	weekly_day = 4

	until 2 < 1 do

		now = Time.now
		hour   = now.hour
		minute = now.min
		day = now.wday

		# -- DAILY JOBS ----
		if hour == start_hour && minute == start_minute

			puts "START to update the json strings for the statistic page."
			StatisticService.update_all
			puts "END to update the json strings for the statistic page."

			puts "START to update integration status of submitted urls"
			SubmittedUrl.update_integration_statuses()
			puts "STOP  to update integration status of submitted urls"

			puts "START to crawl packagist.org"
			PackagistCrawler.crawl
			puts "STOP to crawl packagist.org"

			puts "START update meta data on products."
			ProductMigration.update_meta_data_global
			puts "STOP  update meta data on products."

			puts "START reindex newest products for elastic search"
			EsProduct.index_newest
			puts "STOP reindex newest products for elastic search"

			puts "START to send out the notification E-Mails."
			Notification.send_notifications
			puts "STOP to send out the notification E-Mails."

			puts "START to send out daily project notification E-Mails."
			ProjectService.update_all( Project::A_PERIOD_DAILY )
			puts "STOP to send out daily project notification E-Mails."

			if Time.now.hour == start_hour && Time.now.min == start_minute
				sleep(60)
			end
		end

		# -- WEEKLY JOBS ----
		if day == weekly_day && hour == weekly_hour && minute == weekly_minute

			puts "START to send out the verification reminder E-Mails."
			User.send_verification_reminders
			puts "STOP to send out the verification reminder E-Mails."

			puts "START to send out weekly project notification E-Mails."
			ProjectService.update_all( Project::A_PERIOD_WEEKLY )
			puts "STOP to send out weekly project notification E-Mails."

			if Time.now.hour == weekly_hour && Time.now.min == weekly_minute
				sleep(60)
			end
		end

	end
end

task :update_version_data_global => :environment do
	puts "START update the version numbers on products."
    ProductMigration.update_version_data_global
    puts "STOP update the version numbers on products."
end

task :send_notifications => :environment do
    puts "START to send out the notification E-Mails."
    Notification.send_notifications
    puts "STOP to send out the notification E-Mails."
end

task :send_verification_reminders => :environment do
    puts "START to send out verification reminder E-Mails."
    User.send_verification_reminders
    puts "STOP to send out verification reminder E-Mails."
end
