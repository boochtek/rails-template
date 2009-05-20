require 'rake'

desc 'Test creating a new Rails instance and make sure it works.'
task :test => :rails_test_app do
  %x{cd test && rake features && rake spec}
end

desc 'Run metrics agains the code base.'
task :metrics => :rails_test_app do
  %x{cd test && rake metrics:all}
end

desc 'Create a new Rails instance from the template.'
task :rails_test_app do
  %x{rm -rf test}
  %x{rails --template ./rails-template.rb test}
end
