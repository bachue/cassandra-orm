require "bundler/gem_tasks"

desc 'Run all test cases'
task :test do
  sh 'bundle', 'exec', 'rspec', '-r', './spec/spec_helper', 'spec/examples'
end

task :default => [:test]
