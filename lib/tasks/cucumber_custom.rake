require 'rubygems'

begin

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

rescue LoadError
  desc 'cucumber rake task not available (cucumber not installed)'
  task :cucumber do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end