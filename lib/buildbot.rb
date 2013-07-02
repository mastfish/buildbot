class PullLog < ActiveRecord::Base

  def status_changed?
    return status != last_status
  end

  # statuses: pass | fail | no_tests
  def status
    if (plan_results['size'] == 0)
      return 'no_tests'
    end
    p canonical_result
    if (canonical_result['state'] == "Successful")
      return 'pass'
    end
    if (canonical_result['state'] != "Successful")
      return 'fail'
    end
    raise 'Status should be either pass, fail or no_test'
  end

  def canonical_result
    plan_results['result'].last
  end

  # Cache slooooow API calls
  def plan_results
    if @plan_results
      return @plan_results
    end
    p 'Getting results for ' + last_commit_hash
    url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/result/byChangeset/#{last_commit_hash}"
    req = RestClient::Request.new(
        :method => :get,
        :url => url,
        :headers => { :accept => 'application/json',
        :content_type => 'application/json' }
      ).execute
    results = JSON.parse(req)
    @plan_results = results["results"]
    p @plan_results
    results["results"]
  end

  def status_comment
    case status
    when 'pass'
      return "Build passing at https://bamboo.bigcommerce.net/browse/#{canonical_result["key"]} :green_apple:"
    when 'fail'
      return "Build failing at https://bamboo.bigcommerce.net/browse/#{canonical_result["key"]} :sparkles:"
    when 'no_tests'
      return "No tests have been run for the latest pull in this pull_request :boom:"
    else
      return ''
    end
  end

  def post_status_to_github
    github = Github.new :user => user, :repo => repo, login: "#{ENV['GITUSER']}", password:"#{ENV['GITPASS']}"
    pull = github.pull_requests.list.select{|pull| pull.id == self.pull_id}.first # Highlander: There can be only one
    github.issues.comments.create user, repo, pull.number, "body" => status_comment
    p "Posted #{status_comment}"
  end

end

class BambooWatcher

  def main
    p PullLog.all
    PullLog.where(checked: 0).each do |pull|
      if (pull.status_changed?)
        p "Checked: status changed to #{pull.status}"
        pull.post_status_to_github
        pull.last_status = pull.status
      else
        p 'Checked: Status unchanged'
      end
      pull.checked = 1
      pull.save!
    end
    p 'finished updates'
  end

end

class GitWatcher

  def initialize(user, repo)
    @user = user
    @repo = repo
  end

  def list
    github = Github.new :user => @user, :repo => @repo, login: "#{ENV['GITUSER']}", password:"#{ENV['GITPASS']}"
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
      result.checked = 0
      result.last_commit_hash = pull.head.sha
      result.save!
    end
  end

  def init_or_get_by_pull_id pull_id
    result = PullLog.where(pull_id: pull_id, user: @user, repo: @repo)
    if (result.count == 0)
      out = PullLog.create!(pull_id: pull_id, user: @user, repo: @repo, last_status: '',checked: 0)
    else
      out = result.first
    end
    out
  end

end