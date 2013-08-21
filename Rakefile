require "bundler/gem_tasks"
require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs.push 'test'
end

task :default => :test

task :console do
  Bundler.require
  require "gem_logger"
  ARGV.clear
  require "irb"
  IRB.start
end
