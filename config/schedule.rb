# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#

every 1.day, :at => '1:11 am' do
  rake "versioneye:daily_jobs"
end

every :monday, :at => '6 am' do
  rake "versioneye:weekly_jobs"
end
