require 'github_api'
require 'sqlite3'
require 'active_record'

# Database initialization
db = SQLite3::Database.new 'buildbot_db'
db.execute "CREATE TABLE IF NOT EXISTS pull_logs(id INTEGER PRIMARY KEY, pull_id INTEGER, last_commit_hash TEXT, passing_test INTEGER)"

# Db setup goes here, because why not?
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'buildbot_db'
)

class PullLog < ActiveRecord::Base

  def has_passing_plan?
    return false
  end

  def post_status_to_github
    p 'TBA'
  end

end

class BambooWatcher

  def main
    PullLog.where(passing_test: 0).each do |pull|
      if (pull.has_passing_plan?)
        pull.post_status_to_github
        pull.passing_test = 1
        pull.save!
      end
    end
  end

end

class GitWatcher

  def list
    github = Github.new :user => 'mastfish', :repo => 'buildbot'
    github.pull_requests.list
    # Hitting rate limit on API, mock this for now
    # [OpenStruct.new({
    #   "id"=>6577595,
    #   "head"=> OpenStruct.new({'sha' => '12'})
    #   })]
  end

  def main
    list.each do |pull|
      process_pull pull
    end
  end

  def process_pull pull
    result = init_or_get_by_pull_id(pull.id)
    if (result.last_commit_hash != pull.head.sha)
      result.passing_test = 0
      result.last_commit_hash = pull.head.sha
      result.save!
    end
  end

  def init_or_get_by_pull_id pull_id
    result = PullLog.where(pull_id: pull_id)
    if (result.count == 0)
      out = PullLog.create!(pull_id: pull_id, passing_test: 0)
    else
      out = result.first
    end
    out
  end

end

g = GitWatcher.new
b = BambooWatcher.new
g.main
b.main