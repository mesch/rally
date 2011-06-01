require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'

namespace :cucumber do
  Cucumber::Rake::Task.new(:fast) do |t|
    t.profile = "default"
    t.cucumber_opts = "features --tags ~@deploy"
  end

  Cucumber::Rake::Task.new(:fast_deploy) do |t|
    t.profile = "default"
    t.cucumber_opts = "features --tags @deploy"
  end
end