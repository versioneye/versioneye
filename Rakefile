#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Versioneye::Application.load_tasks

task :update_version_data_global => :environment do
    puts "START update the version numbers on products."
    Product.update_version_data_global
    puts "STOP update the version numbers on products."
end

task :send_notifications => :environment do
    puts "START to send out the notification E-Mails."
    Notification.send_notifications
    puts "STOP to send out the notification E-Mails."
end
