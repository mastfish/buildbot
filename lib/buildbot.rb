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
    plan_results
  end

  # Cache slooooow API calls
  def plan_results
    if @plan_results
      return @plan_results
    end
    p 'Getting results for ' + last_commit_hash
    api = BambooAPI.new
    results = api.result_by_changeset(last_commit_hash)
    # results = {"link"=>{"href"=>"http://127.0.0.1:8085/rest/api/latest/result/TC-BC3-2", "rel"=>"self"}, "master"=>{"shortName"=>"Bigcommerce", "shortKey"=>"BC", "type"=>"chain", "enabled"=>true, "link"=>{"href"=>"http://127.0.0.1:8085/rest/api/latest/plan/TC-BC", "rel"=>"self"}, "key"=>"TC-BC", "name"=>"Tom Cully - Bigcommerce"}, "lifeCycleState"=>"Finished", "id"=>82679277, "key"=>"TC-BC3-2", "state"=>"Failed", "number"=>2}
    @plan_results = results
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
  @@branches = {}
  @@test_results = {}
  @@detailed_test_results = {}
  @@plans = nil

  def result_by_changeset(sha)
    url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/result/byChangeset/#{sha}"
    req = RestClient::Request.new(
        :method => :get,
        :url => url,
        :headers => { :accept => 'application/json',
        :content_type => 'application/json' }
      ).execute
    results = JSON.parse(req)

    if (results['results']['size'] == 0)
      plans.each do |plan|
        p 'plan start'
        branches(plan).each do |branch|
          test_results(branch).each do |test_result|
            if result_match_changeset?(test_result, sha)
              return test_result
            end
          end
        end
      end
    else
      return results['results']['result'].last
    end
  end

  def result_match_changeset?(test_result, sha)
    if @@detailed_test_results[test_result['key']]
      return @@detailed_test_results[test_result['key']]
    end
    url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/result/#{test_result['key']}"
      req = RestClient::Request.new(
          :method => :get,
          :url => url,
          :headers => { :accept => 'application/json',
          :content_type => 'application/json' }
        ).execute
    results = JSON.parse(req)
    return sha == results['vcsRevisionKey']
  end


  def test_results(branch)
    if @@test_results[branch['key']]
      return @@test_results[branch['key']]
    end
    out = []
    url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/result/#{branch['key']}"
      req = RestClient::Request.new(
          :method => :get,
          :url => url,
          :headers => { :accept => 'application/json',
          :content_type => 'application/json' }
        ).execute
    results = JSON.parse(req)
    out += results['results']['result']
    @@test_results[branch['key']] = out
    out
  end

  def plans
    if @@plans
      return @@plans
    end
    out = []
    total_size = 1 #start the process
    while (out.count < total_size)
      url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/plan?start-index=#{out.count}"
      req = RestClient::Request.new(
          :method => :get,
          :url => url,
          :headers => { :accept => 'application/json',
          :content_type => 'application/json' }
        ).execute
      results = JSON.parse(req)
      total_size = results['plans']['size']
      out += results['plans']['plan']
    end
    @@plans = out
    out
  end

  def branches(plan)
    if @@branches[plan['key']]
      return @@branches[plan['key']]
    end
    out = []
    url = "https://#{ENV['BAMBOOUSER']}:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/plan/#{plan['key']}/branch"
      req = RestClient::Request.new(
          :method => :get,
          :url => url,
          :headers => { :accept => 'application/json',
          :content_type => 'application/json' }
        ).execute
    results = JSON.parse(req)
    out += results['branches']['branch']
    @@branches[plan['key']] = out
    out
  end

end