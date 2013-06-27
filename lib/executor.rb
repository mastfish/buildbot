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

  API_BASE = 'https://bamboo.bigcommerce.net/rest/api/latest/'

  A = API_BASE
  R = RestClient # I'm hella lazy

  class PullLog < ActiveRecord::Base
  end

  class BuildQueue < ActiveRecord::Base
  end
  #end test

  def main
    BuildQueue.where(locked_at: nil).each do |build_trigger|
      trigger_build build_trigger
    end
  end

  def trigger_build build_trigger
    pull = PullLog.where(pull_id: build_trigger.pull_id)
    payload = {os_authType: 'basic', os_username: &os_password=<pw>}
    res = R.put A + 'clone/BUILDBOT-MAIN:BUILDNOT-FIRST', '{}', :content_type => 'application/json'
  end

end

# Test code
e = Executor.new
e.main