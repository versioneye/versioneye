#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Versioneye::Application.load_tasks

namespace :db do

  desc "db:migration fakes"
  task :migrate => :environment do
    p 'No. We will not migrate!'
  end

end
