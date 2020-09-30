require File.expand_path(File.dirname(__FILE__) + '/lib/active_snapshot/version.rb')

require "bundler/gem_tasks"
require "rake/testtask"
#require 'rails/dummy/tasks'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test

task :console do
  require 'active_snapshot'

  require 'irb'
  binding.irb
end
