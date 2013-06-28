# Db setup goes here, because why not?
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'buildbot_db'
)

class PullLog < ActiveRecord::Base
end

class BuildQueue < ActiveRecord::Base
end

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

  def check_for_passing_plans hash
    result = mongo.where(tag: hash)
    if (result.count == 0)
      p 'false'
    else
      p 'true'
    end
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
      check_for_passing_plans pull.head.sha
      result.last_commit_hash = pull.head.sha
      result.save!
    end
  end

  def init_db
    db = SQLite3::Database.new 'buildbot_db'
    db.execute "CREATE TABLE IF NOT EXISTS pull_logs(id INTEGER PRIMARY KEY, pull_id INTEGER, last_commit_hash TEXT, passing_test INTEGER)"
    db
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