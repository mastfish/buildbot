class Executor

  # Test code
  # These requires are only needed to support development
  require 'github_api'
  require 'sqlite3'
  require 'active_record'
  require 'rest_client'

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
    url = "https://justin.lambert:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/clone/BUILDBOT-MAIN:BUILDBOT-FIRST?os_authType=basic"
    req = RestClient::Request.new(
      :method => :put,
      :url => url,
      :headers => { :accept => 'application/json',
      :content_type => 'application/json' }
    ).execute
  end

  def update_info
    payload = test_payload
    url = "https://bamboo.bigcommerce.net/chain/admin/config/updateRepository.action"
    begin
      req = RestClient::Request.new(
        :method => :post,
        :url => url,
        :headers => { :accept => 'text/html'},
        :payload => payload,
        :cookies => test_cookies,
        :multipart => true
      ).execute
    rescue => e
      binding.pry
    end
  end

  def test_cookies
    {
      "BAMBOO-BUILD-FILTER" => "LAST_25_BUILDS",
      "BAMBOO-DEFAULT-REPOSITORY" => "com.atlassian.bamboo.plugins.atlassian-bamboo-plugin-git:gh",
      "JSESSIONID" => "1evg11ynr72cdb5g00oqt180x",
      "seraph.bamboo" => "83722248%3A5d9db4535c3214988cc54b9257ecf10f90bc4a75",
      "atlassian.bamboo.dashboard.tab.selected" => "allPlansTab",
      "BAMBOO-MAX-DISPLAY-LINES" => "25",
      "bamboo.dash.display.toggles" => "buildQueueActions-actions-queueControl",
    }
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
      "changeset.filter.pattern.regex" => "OHAI",
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