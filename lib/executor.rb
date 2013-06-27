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

  R = RestClient # I'm hella lazy

  class PullLog < ActiveRecord::Base
  end

  class BuildQueue < ActiveRecord::Base
  end
  #end test

  def main
    url ="https://justin.lambert:#{ENV['PASSWORD']}@bamboo.bigcommerce.net/rest/api/latest/clone/BUILDBOT-MAIN:BUILDNOT-FIRST?os_authType=basic"
    begin
      req = RestClient::Request.new(
        :method => :put,
        :url => url,
        :headers => { :accept => 'application/json',
        :content_type => 'application/json' }
      ).execute
      binding.pry
    rescue => e
      binding.pry
    end
    # BuildQueue.where(locked_at: nil).each do |build_trigger|
    #   trigger_build build_trigger
    # end
  end

  def trigger_build build_trigger
    pull = PullLog.where(pull_id: build_trigger.pull_id)
    #
  end

end

# Test code
e = Executor.new
e.main