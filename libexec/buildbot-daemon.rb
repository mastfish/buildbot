# Generated cron daemon
require 'sqlite3'
require 'active_record'
require 'rest_client'
require 'json'
require 'pry'

DB_PATH = "#{__dir__}/../db/buildbot_db"
REPOS = [
          {user: 'mastfish', repo: 'buildbot'},
          {user: 'bigcommerce', repo: 'new-mobile'}
        ]

# Database initialization
db = SQLite3::Database.new DB_PATH
db.execute "CREATE TABLE IF NOT EXISTS pull_logs(id INTEGER PRIMARY KEY, pull_id INTEGER, last_commit_hash TEXT, user STRING, repo STRING, passing_test INTEGER)"


# Do your post daemonization configuration here
# At minimum you need just the first line (without the block), or a lot
# of strange things might start happening...
DaemonKit::Application.running! do |config|
  # Trap signals with blocks or procs
  # config.trap( 'INT' ) do
  #   # do something clever
  # end
  # config.trap( 'TERM', Proc.new { puts 'Going down' } )
end

# Configuration documentation available at http://rufus.rubyforge.org/rufus-scheduler/
# An instance of the scheduler is available through
# DaemonKit::Cron.scheduler

# To make use of the EventMachine-powered scheduler, uncomment the
# line below *before* adding any schedules.
# DaemonKit::EM.run

# Some samples to get you going:

# Will call #regenerate_monthly_report in 3 days from starting up
#DaemonKit::Cron.scheduler.in("3d") do
#  regenerate_monthly_report()
#end
#
#DaemonKit::Cron.scheduler.every "10m10s" do
#  check_score(favourite_team) # every 10 minutes and 10 seconds
#end
#
#DaemonKit::Cron.scheduler.cron "0 22 * * 1-5" do
#  DaemonKit.logger.info "activating security system..."
#  activate_security_system()
#end
#
# Example error handling (NOTE: all exceptions in scheduled tasks are logged)
#DaemonKit::Cron.handle_exception do |job, exception|
#  DaemonKit.logger.error "Caught exception in job #{job.job_id}: '#{exception}'"
#end

DaemonKit::Cron.scheduler.every("30s") do
  # Db setup goes here, because why not?
  ActiveRecord::Base.establish_connection(
    :adapter => 'sqlite3',
    :database => DB_PATH
  )
  DaemonKit.logger.debug "GitWatcher task started at #{Time.now}"
  REPOS.each do |repo|
    gwatcher = GitWatcher.new repo[:user], repo[:repo]
    gwatcher.main
  end
  DaemonKit.logger.debug "GitWatcher task completed at #{Time.now}"
end

DaemonKit::Cron.scheduler.every("1m") do
  ActiveRecord::Base.establish_connection(
    :adapter => 'sqlite3',
    :database => DB_PATH
  )
  DaemonKit.logger.debug "BambooWatcher task started at #{Time.now}"
  bwatcher = BambooWatcher.new
  bwatcher.main
  DaemonKit.logger.debug "BambooWatcher task completed at #{Time.now}"
end


# Run our 'cron' dameon, suspending the current thread
DaemonKit::Cron.run
