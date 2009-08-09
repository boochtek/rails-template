require 'rake'

task :default => [:test]

desc 'Test creating a new Rails instance.'
task :test => :rails_test_app do
  %x{cd test && rake features && rake spec}
end

namespace :test do
  desc 'Test creating a new Rails instance and make sure it works.'
  task :full => :rails_test_app do
    %x{cd test && script/generate model TestModel field1:integer field2:string field3:boolean && rake db:migrate && rake spec}
    # TODO: Need to add a route for the controller, before we can test the controller.
    %x{cd test && script/generate controller TestController index new create edit show update delete destroy && rake spec && rake features}
    %x{cd test && script/generate feature Test field1:integer field2:string field3:boolean && rake features}
  end  
end

desc 'Run metrics agains the code base.'
task :metrics => :rails_test_app do
  %x{cd test && rake metrics:all}
end

desc 'Create a new Rails instance from the template.'
task :rails_test_app do
  %x{rm -rf test}
  options = 'ACTIVERECORD=y DATAMAPPER=n SUBMODULE=n ACTIONMAILER=n ACTIVERESOURCE=n HOPTOAD=n EXCEPTIONNOTIFIER=n'
  %x{env #{options} rails --template ./rails-template.rb test}
end
