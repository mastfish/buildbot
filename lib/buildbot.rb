# Db setup goes here, because why not?
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'buildbot_db'
)

class PullLog < ActiveRecord::Base
end

class BuildQueue < ActiveRecord::Base
end

require_relative 'executor'
require_relative 'watcher'