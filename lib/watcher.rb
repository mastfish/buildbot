require 'github_api'
require 'sqlite3'

class Watcher

  def main
    github = Github.new :user => 'mastfish', :repo => 'buildbot'

    github.pull_requests.list.each do |pull|
      process_pull pull
    end
  end

  def process_pull pull
    # Here we assume any new commits will be added to the head
    # No rebasing shenanigans
    save_pull(pull.id,pull.head.sha)
  end

# lotta raw sql here
# TODO: add activerecord based DB accessor classes

# TODO, de-SQL-ify
  def init_db
    db = SQLite3::Database.new 'buildbot_db'
    db.execute "CREATE TABLE IF NOT EXISTS pull_log(id INTEGER PRIMARY KEY, pull_id INTEGER, last_commit_hash TEXT, build_triggered INTEGER)"
    db
  end

# TODO, de-SQL-ify
  def save_pull pull_id, last_commit_hash
    db = init_db
    result = db.execute "SELECT * from pull_log WHERE pull_id = '#{pull_id}'"
    if (result.count == 0)
      db.execute "INSERT INTO pull_log(pull_id, last_commit_hash, build_triggered) VALUES (#{pull_id}, '#{last_commit_hash}', 0)"
      result = db.execute "SELECT * from pull_log WHERE pull_id = '#{pull_id}'"
    end
    result.inspect
  end

end
