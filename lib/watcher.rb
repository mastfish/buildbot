class Watcher

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
    init_db
    list.each do |pull|
      process_pull pull
    end
  end

  def process_pull pull
    result = init_or_get_by_pull_id(pull.id)
    if (result.last_commit_hash != pull.head.sha)
      BuildQueue.create!(pull_id: pull.id)
      result.last_commit_hash = pull.head.sha
      result.save!
    end
  end

  def init_db
    db = SQLite3::Database.new 'buildbot_db'
    db.execute "CREATE TABLE IF NOT EXISTS pull_logs(id INTEGER PRIMARY KEY, pull_id INTEGER, last_commit_hash TEXT, build_triggered INTEGER)"
    db.execute "CREATE TABLE IF NOT EXISTS build_queues(id INTEGER PRIMARY KEY, pull_id INTEGER, locked_at INTEGER)"
    db
  end

  def init_or_get_by_pull_id pull_id
    result = PullLog.where(pull_id: pull_id)
    if (result.count == 0)
      out = PullLog.create!(pull_id: pull_id, build_triggered: 0)
    else
      out = result.first
    end
    out
  end

end