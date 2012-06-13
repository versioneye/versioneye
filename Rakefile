#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Versioneye::Application.load_tasks

task :do_work => :environment do
	puts "START"

	start_hour = 23
	start_minute = 10

	until 2 < 1 do 
		now = Time.now
		hour   = now.hour
		minute = now.min
		if hour == start_hour && minute == start_minute

			puts "START update the version numbers on products."
		    Product.update_version_data_global
		    puts "STOP update the version numbers on products."

		    puts "START to send out the notification E-Mails."
		    Notification.send_notifications
		    puts "STOP to send out the notification E-Mails."
			
			if Time.now.hour == start_hour && Time.now.min == start_minute 
				sleep(60)
			end
		end
	end	
end

task :update_version_data_global => :environment do
	puts "START"
	puts "START update the version numbers on products."
    #Product.update_version_data_global
    puts "STOP update the version numbers on products."
end

task :send_notifications => :environment do
    puts "START to send out the notification E-Mails."
    #Notification.send_notifications
    puts "STOP to send out the notification E-Mails."
end
