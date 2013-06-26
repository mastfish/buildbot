class Watcher

  def main
    github = Github.new :user => 'mastfish', :repo => 'buildbot'
    github.pull_requests.list.each do |pull|
      process_pull pull
    end
  end

  def pull pull
    p pull.inspect
  end

end