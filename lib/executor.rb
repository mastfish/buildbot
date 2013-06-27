class Executor

  # Test code
  # These requires are only needed to support development
  require 'github_api'
  require 'sqlite3'
  require 'active_record'
  require 'rest_client'

  API_BASE = "https://justin.lambert:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/"

  ActiveRecord::Base.establish_connection(
    :adapter => 'sqlite3',
    :database => 'buildbot_db'
  )

  class PullLog < ActiveRecord::Base
  end

  class BuildQueue < ActiveRecord::Base
  end
  #end test

  def main
    update_info
    # BuildQueue.where(locked_at: nil).each do |build_trigger|
    #   trigger_build build_trigger
    # end
  end

  def trigger_build build_trigger
    pull = PullLog.where(pull_id: build_trigger.pull_id)
  end

  def clone
    url = API_BASE + "rest/api/latest/clone/BUILDBOT-MAIN:BUILDBOT-FIRST?os_authType=basic"
    req = RestClient::Request.new(
      :method => :put,
      :url => url,
      :headers => { :accept => 'application/json',
      :content_type => 'application/json' }
    ).execute
  end

  def update_info
    payload = test_payload
    url = API_BASE + "chain/admin/config/updateRepository.action"
    req = RestClient::Request.new(
      :method => :post,
      :url => url,
      :headers => { :accept => 'text/html'},
      :payload => payload,
      :multipart => true
    ).execute
    binding.pry
  end

  def test_payload
    {
      "PlanKey" => "BUILDBOT-FIRST",
      "repositoryId" => "83132573",
      "selectedRepository" => "com.atlassian.bamboo.plugins.atlassian-bamboo-plugin-git\":gh",
      "selectFields" => "selectedRepository",
      "repositoryName" => "GitHub",
      "repository.github.username" => "mastfish",
      "temporary.github.password.change" => "true",
      "repository.github.temporary.password" => "",
      "repository.github.repository" => "mastfish/buildbot",
      "selectFields" => "repository.github.repository",
      "repository.github.branch" => "dev",
      "selectFields" => "repository.github.branch",
      "repository.github.useShallowClones" => "true",
      "checkBoxFields" => "repository.github.useShallowClones",
      "checkBoxFields" => "repository.github.useSubmodules",
      "repository.github.commandTimeout" => "180",
      "checkBoxFields" => "repository.github.verbose.logs",
      "checkBoxFields" => "repository.common.quietPeriod.enabled",
      "repository.common.quietPeriod.period" => "10",
      "repository.common.quietPeriod.maxRetries" => "5",
      "filter.pattern.option" => "none",
      "selectFields" => "filter.pattern.option",
      "filter.pattern.regex" => "",
      "changeset.filter.pattern.regex" => "",
      "selectedWebRepositoryViewer" => "bamboo.webrepositoryviewer.provided\":noRepositoryViewer",
      "selectFields" => "selectedWebRepositoryViewer",
      "webRepository.genericRepositoryViewer.webRepositoryUrl" => "",
      "webRepository.genericRepositoryViewer.webRepositoryUrlRepoName" => "",
      "webRepository.stash.url" => "",
      "webRepository.stash.project" => "",
      "webRepository.stash.repositoryName" => "",
      "webRepository.fisheyeRepositoryViewer.webRepositoryUrl" => "",
      "webRepository.fisheyeRepositoryViewer.webRepositoryRepoName" => "",
      "webRepository.fisheyeRepositoryViewer.webRepositoryPath" => "",
      "webRepository.hg.scheme" => "bitbucket",
      "selectFields" => "webRepository.hg.scheme",
      "bamboo.successReturnMode" => "json-as-html",
      "decorator" => "nothing",
      "confirm" => "true",
    }
  end

  def send_build_request

  end

end

# Test code
e = Executor.new
e.main