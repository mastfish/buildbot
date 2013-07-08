class PullLog < ActiveRecord::Base

  def status_changed?
    return status != last_status
  end

  # statuses: pass | fail | no_tests
  def status
    if (canonical_result['state'] == "Successful")
      return 'pass'
    end
    if (canonical_result['state'] != "Successful")
      return 'fail'
    end
    return 'no_tests'
  end

  def canonical_result
    plan_results
  end

  # Cache slooooow API calls
  def plan_results
    p 'Getting results for ' + last_commit_hash
    api = BambooAPI.new
    results = api.result_by_changeset(last_commit_hash)
    results
  end

  def status_comment
    case status
    when 'pass'
      return "Build passing at https://bamboo.bigcommerce.net/browse/#{canonical_result["key"]} :green_apple:"
    when 'fail'
      return "Build failing at https://bamboo.bigcommerce.net/browse/#{canonical_result["key"]} :sparkles:"
    when 'no_tests' # not used right now
      return "No tests have been run for the latest pull in this pull_request :boom:"
    else
      return ''
    end
  end

  def post_status_to_github
    github = Github.new :user => user, :repo => repo, login: "#{ENV['GITUSER']}", password:"#{ENV['GITPASS']}"
    pull = github.pull_requests.list.select{|pull| pull.id == self.pull_id}.first # There can be only one
    if (pull) # might have already been closed
      github.issues.comments.create user, repo, pull.number, "body" => status_comment
    end
    p "Posted #{status_comment}"
  end

end

class BambooWatcher

  def main
    p PullLog.all
    PullLog.where(checked: 0).each do |pull|
      if (pull.status_changed? && (pull.status != 'no_tests'))
        p "Checked: status changed to #{pull.status}"
        pull.post_status_to_github
        pull.last_status = pull.status
        pull.checked = 1
        pull.save!
      else
        # p 'Checked: Status unchanged, or no tests found'
      end
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

class BambooAPI
  require 'rest_client'
  require 'json'
  require 'pry'

  def result_by_changeset(sha)
    url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/result/byChangeset/#{sha}"
    results = request url
    result = nil
    if (results['results']['size'] == 0)
      # plans.each do |plan|
        plan = {'key' => 'BUILDBOT-FIRST'}
        p "testing #{plan['key']}"
        branches(plan).each do |branch|
          test_results(branch).each do |test_result|
            if result_match_changeset?(test_result, sha)
              return test_result
            end
          end
        end
      # end
    else
      return results['results']['result'].last
    end
  end

  def result_match_changeset?(test_result, sha)
    url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/result/#{test_result['key']}"
    results = request url
    return sha == results['vcsRevisionKey']
  end


  def test_results(branch)
    out = []
    url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/result/#{branch['key']}"
    results = request url
    out += results['results']['result']
    out
  end

  def plans
    out = []
    total_size = 1 #start the process
    while (out.count < total_size)
      url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/plan?start-index=#{out.count}"
      results = request url
      total_size = results['plans']['size']
      out += results['plans']['plan']
    end
    out
  end

  def branches(plan)
    out = []
    url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/plan/#{plan['key']}/branch"
    results = request url
    out += results['branches']['branch']
    out
  end

  def request(target)
    req = RestClient::Request.new(
          :method => :get,
          :url => target,
          :headers => { :accept => 'application/json',
          :content_type => 'application/json' }
        ).execute
    results = JSON.parse(req)
    results
  end

end