class Buildbot
  def hello
    github = Github.new :user => 'mastfish', :repo => 'buildbot'
    p github.pull_requests.list
  end
end