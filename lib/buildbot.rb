require 'github_api'
require 'sqlite3'
require 'active_record'
require 'rest_client'
require 'json'
require 'pry'
DB_PATH = "#{__dir__}/buildbot_db"

# Database initialization
db = SQLite3::Database.new DB_PATH
db.execute "CREATE TABLE IF NOT EXISTS pull_logs(id INTEGER PRIMARY KEY, pull_id INTEGER, last_commit_hash TEXT, passing_test INTEGER)"

# Db setup goes here, because why not?
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => DB_PATH
)

class PullLog < ActiveRecord::Base

  def has_passing_plan?
    p 'testing for ' + last_commit_hash
    url = "https://justin.lambert:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/result/byChangeset/#{last_commit_hash}"
    req = RestClient::Request.new(
        :method => :get,
        :url => url,
        :headers => { :accept => 'application/json',
        :content_type => 'application/json' }
      ).execute
    results = JSON.parse(req)
    results["results"]["result"].each do |result|
      @link = "https://bamboo.bigcommerce.net/browse/#{result["key"]}"
      if (result["state"] == "Successful")
        return true
      end
    end
    return false
  end

  def post_status_to_github
    comment = @link + ' :green_apple:'
    github = Github.new :user => 'mastfish', :repo => 'buildbot', login:'mastfish', password:"#{ENV['GITPASS']}"
    github.issues.comments.create 'mastfish', 'buildbot', '1', "body" => comment
    p 'Passed'
  end

end

class BambooWatcher

  def main
    PullLog.where(passing_test: 0).each do |pull|
      if (pull.has_passing_plan?)
        pull.post_status_to_github
        pull.passing_test = 1
        pull.save!
      else
        p 'Not passed'
      end
    end
    p 'finished updates'
  end

end

class GitWatcher

  def list
    github = Github.new :user => 'mastfish', :repo => 'buildbot'
    github.pull_requests.list
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