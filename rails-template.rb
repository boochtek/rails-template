#!/bin/env ruby

# Rails template. Loads RSpec, Cucumber, HAML, Sass, Slim, jQuery, etc.
# In many ways, this is a collection of my personal knowledge, opinions, and best practices regarding Rails.

# Copyright 2008,2009,2013 by BoochTek, LLC.
# Originally written by Craig Buchek.
# Released under MIT license (same as Ruby on Rails).


# Got some of these ideas and code from other templates, including http://github.com/jeremymcanally/rails-templates/ and http://github.com/ffmike/BigOldRailsTemplate/.


## Get user input, via environment variables or prompting the user.
activerecord = ENV['ACTIVERECORD'] ? ENV['ACTIVERECORD'] == 'y' : yes?('Include ActiveRecord?')
email = ENV['ACTIONMAILER'] ? ENV['ACTIONMAILER'] == 'y' : yes?('Include ActionMailer?')
airbrake = ENV['AIRBRAKE'] ? ENV['AIRBRAKE'] == 'y' : yes?('Use Airbrake Notifier?')
exception_notifier = ENV['EXCEPTIONNOTIFIER'] ? ENV['EXCEPTIONNOTIFIER'] == 'y' : yes?('Use Exception Notifier?')
email = true if exception_notifier      # Force email if we've enabled a plugin that requires it.


# Allow opening URLs as if they are local files.
require 'open-uri'

# Include FileUtils functionality. Note that we can't use include or define_method from within this app template file.
require 'fileutils'
def cp(src, dest, options = {}); FileUtils.cp(src, dest, options); end
def mv(src, dest, options = {}); FileUtils.mv(src, dest, options); end
def mkdir_p(list, options = {}); FileUtils.mkdir_p(list, options); end
def rm_f(list, options = {}); FileUtils.rm_f(list, options); end
def touch(list, options = {}); FileUtils.touch(list, options); end


## Decide whether to pull all the files from local directory, or from GitHub.
RAILS_TEMPLATE_PATH = File.dirname(rails_template)
if rails_template.match(%r{^/})
  running_local = true
else
  running_local = false
end

# Check to ensure that we can get to all the files we need.
begin
  open("#{RAILS_TEMPLATE_PATH}/rails-template.rb")
rescue
  raise 'You need to have an Internet connection for this template to work.'
end


# Make it easy to pull files from the template repository into the project.
def pull_file(path, options={})
  create_file "#{path}", open("#{RAILS_TEMPLATE_PATH}/#{path}").read, options
rescue
  puts "ERROR - Could not pull file."
  exit!
end

# Helper to make it easier to install gems.
def bundle
  bundle_command 'install --path vendor/bundle'
end

# Start a new GIT repository. Do this first, in case we want to install some GEMS as GIT submodules.
git :init


## Optionally remove some portions of the standard Rails stack.

# Make sure that the config/application.rb lists the individual frameworks, so we can remove ones we don't want.
# The 'rails new' command will use "require 'rails/all'" if none of the --skip options are used, and these individual lines otherwise.
gsub_file 'config/application.rb', %r(^require 'rails/all'$), <<'EOF'
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"
EOF


# ActiveRecord ORM.
if activerecord
  gem 'annotate', '~> 2.5', groups: [:development], require: false
  bundle
  generate 'annotate:install'
else
  gsub_file 'config/application.rb', %r(^require "active_record/railtie"$), '#require "active_record/railtie"'
  ['development', 'test', 'production'].each do |env|
    gsub_file "config/environments/#{env}.rb", %r(^  config\.active_record\.), '  #config.active_record.'
  end
end

# ActionMailer
if !email
  gsub_file 'config/application.rb', %r(^require "action_mailer/railtie"$), '#require "action_mailer/railtie"'
  ['development', 'test', 'production'].each do |env|
    gsub_file "config/environments/#{env}.rb", %r(^  config\.action_mailer\.), '  #config.action_mailer.'
  end
end


## Database config.
mv 'config/database.yml', 'config/database.yml.sample'
pull_file 'config/database.yml'

if activerecord
  # Use the Bullet gem to alert developers of unoptimized SQL queries.
  gem 'bullet', :version => '~> 4.6', groups: [:development, :test]
  pull_file 'config/initializers/bullet.rb'
end


## Testing frameworks.
gem 'rspec',              '~> 2.13',  groups: ['development', 'test']
gem 'rspec-rails',        '~> 2.13',  groups: ['test']
gem 'bogus',              '~> 0.1.0', groups: ['test']
gem 'cucumber',           '~> 1.3',   groups: ['development', 'test']
gem 'cucumber-rails',     '~> 1.3',   groups: ['test']
gem 'capybara',           '~> 2.1',   groups: ['test']
gem 'factory_girl_rails', '~> 4.2',   groups: ['development', 'test']
gem 'shoulda',            '~> 3.5',   groups: ['test']
gem 'shoulda-matchers',   '~> 2.2',   groups: ['test']
gem 'jasmine',            '~> 1.3',   groups: ['development', 'test']

# Make sure we've got the rspec and cucumber GEMs installed, before we run their generators.
bundle

# Create databases.
if activerecord
  rake 'db:create:all'
end

# Create spec directory structure.
generate 'rspec:install'


# Pull in RSpec support files and matchers.
# TODO: Should we try to put some of these in GEMs (see how Shoulda does it)?
pull_file 'spec/support/running.rb'
pull_file 'spec/support/require.rb'
pull_file 'spec/support/shoulda.rb'
pull_file 'spec/support/email_spec_helper.rb'
pull_file 'spec/support/matchers/be_in.rb'
pull_file 'spec/support/matchers/be_sorted.rb'
pull_file 'spec/support/matchers/allow_values.rb'
pull_file 'spec/support/matchers/rails.rb'
pull_file 'spec/support/matchers/should_each.rb'


# Create features directory for Cucumber, as well as a cucumber config file.
generate 'cucumber:install'
gsub_file 'config/cucumber.yml', /rerun\.txt/, 'features/rerun.txt' # Move the rerun flag file.
gsub_file 'config/cucumber.yml', /--strict/, '--guess' # Guess the right step to use when more than one matches.


# Allow use of FactoryGirl factories in Cucumber.
pull_file 'features/support/factory_girl.rb'
mkdir_p 'spec/factories'


# TODO: Create some commonly-used feature steps for use in Cucumber.


# Background job processing.
gem 'sidekiq', '~> 2.12'
bundle


# Specs and steps for email.
if email
  gem 'email_spec', '~> 1.4', groups: ['test'] # See http://github.com/bmabey/email-spec for docs.
  bundle
  generate 'email_spec' # Generate email_steps.rb file.
  pull_file 'features/support/email_spec.rb' # Integration into Cucumber.
  pull_file 'spec/support/email_spec_helper.rb' # Integration into RSpec.
  # USAGE:
  #   In features:
  #     Then I should receive an email
  #     When I open the email
  #     Then I should see "blah" in the subject
  #     When I click the first link in the email
  #   In steps:
  #     def current_email_address; @email || (@current_user && @current_user.email) || 'unknown@example.com'
  #     unread_emails_for(current_email_address).size.should == 1
  #     open_email(current_email_address)
  #     current_email.should have_subject(/blah/)
  #     click_first_link_in_email()
end

# Create spec/javascripts directory structure.
generate 'jasmine:install'
generate 'jasmine:examples'


## TODO: Create some sample specs and features that we can start with.
# NOTE: Be sure to make use of Shoulda RSpec matchers.
#       http://github.com/thoughtbot/shoulda/tree/master/lib/shoulda/active_record/matchers
#       http://github.com/thoughtbot/shoulda/tree/master/lib/shoulda/action_controller/matchers
# NOTE: Be sure to use the new syntax in features.
#         Background (like a Scenario section, but runs before each Scenario, and after the Before section).


## Stats and coverage tools.
gem 'metric_fu', '~> 4.2.1', groups: ['development' 'test']
append_file 'Rakefile', "require 'metric_fu'"


# Slim templating system.
gem 'slim-rails', '~> 2.0'


# HAML templating system.
gem 'haml', '~> 4.0'
run 'haml --rails .'

# Sass CSS templating.
gem 'sass', '~> 3.2'


# jQuery for client-side scripting. NOTE: We inject JQUERY_VERSION into site_config.rb below.
JQUERY_VERSION = '2.0.2'
file "vendor/assets/javascripts/jquery-#{JQUERY_VERSION}.js", open("http://code.jquery.com/jquery-#{JQUERY_VERSION}.js").read
pull_file 'app/helpers/jquery_helper.rb'

# Pull in my custom JavaScript code.
pull_file 'public/javascripts/boochtek.js'
pull_file 'public/javascripts/boochtek/validation.js'
pull_file 'public/javascripts/boochtek/google-analytics.js'


## Error notification.
if airbrake
  gem 'airbrake'
  bundle
  generate "airbrake --api-key #{ask('Airbrake API Key:')}"
end

if exception_notifier
  gem 'exception_notification', '~> 4.0.0rc1'
  bundle
  generate 'exception_notification:install --sidekiq'
  exception_sender = ask('Send exception emails from (Name <address>):')
  exception_recipients = ask('Send exception emails to (space-separated list):')
  gsub_file 'config/initializers/exception_notification.rb', /:email_prefix.*/, ":email_prefix => '[#{app_name.classify}] ',"
  gsub_file 'config/initializers/exception_notification.rb', /:sender_address.*/, ":sender_address => %{#{exception_sender}},"
  gsub_file 'config/initializers/exception_notification.rb', /:exception_recipients.*/, ":exception_recipients => %w[#{exception_recipients}]"
  # TODO: Add info on the current_user.
  #     Step 1: Add info to request.env["exception_notifier.exception_data"][:current_user] (probably in a before_filter in ApplicationController).
  #     Step 2: Create app/views/exception_notifier/_current_user.text.erb with the details from @current_user.
  #     Step 3: Add to email section of config: sections: ExceptionNotifier.sections + %w[current_user]
end


pull_file 'app/controllers/application_controller.rb', force: true


## My personal plugins.
#plugin 'default_views', :git => "git://github.com/boochtek/rails-default_views.git", :submodule => true
#plugin 'crud_actions', :git => "git://github.com/boochtek/rails-crud_actions.git", :submodule => true
#plugin 'attribute_declarations', :git => 'git://github.com/boochtek/activerecord-attribute_declarations.git', :submodule => true


## Default HTML code.
# Default layout.
pull_file 'app/views/layouts/application.html.erb', force: true
# TODO: 404 and other files in public.

# Display a custom message when site is down for maintenance. From Advanced Rails Recipes #69.
# Use 'cap deploy:web:disable' to display the maintenance page, and 'cap deploy:web:enable' to return to normal service.
pull_file 'app/views/admin/maintenance.html.erb'
pull_file 'public/.htaccess'
pull_file 'config/deploy/maintenance.rb'

## Delete some unnecessary files.
rm_f 'README' # Needed for rake doc:rails for some reason.
rm_f 'doc/README_FOR_APP' # Needed for rake doc:app for some reason.
rm_f 'public/index.html'
rm_f 'public/images/rails.png'
#rm_f 'public/favicon.ico' # TODO: Really need to make sure favicon.ico is available, as browsers request it frequently.
#rm_f 'public/robots.txt'  # TODO: Add a robots.txt to ignore everything, so app starts in "stealth mode"? At least for staging?


## Default assets.
# Add some images used by the HTML, CSS, and JavaScript.
pull_file 'public/stylesheets/application.css'
pull_file 'public/images/invalid.gif'


## Other


# Footnotes at bottom of site when in development, with lots of info and links.
# TODO: Set up so we can use textmate links to edit files directly from web pages.
# TODO: Add more notes types. Notes on model methods, SQL table name/row-count/schema (info on each field).
gem 'rails-footnotes', '~> 3.7', groups: [:development]
generate 'rails_footnotes:install'
pull_file 'lib/footnotes/current_user_note.rb'
pull_file 'lib/footnotes/global_constants_note.rb'
inject_into_file 'config/initializers/rails_footnotes.rb', :after => '# ... other init code' do
  <<-'EOF'
    require 'footnotes/current_user_note'
    require 'footnotes/global_constants_note'
    Footnotes::Filter.notes -= [:general] # I don't see the point of this note.
    Footnotes::Filter.notes += [:current_user, :global_constants] # Add our custom note.
  EOF
end


## My custom generators.
pull_file 'lib/generators/controller/USAGE'
pull_file 'lib/generators/controller/controller_generator.rb'
pull_file 'lib/generators/controller/templates/controller_spec.rb'
pull_file 'lib/generators/controller/templates/helper_spec.rb'
pull_file 'lib/generators/controller/templates/controller.rb'
pull_file 'lib/generators/controller/templates/functional_test.rb'
pull_file 'lib/generators/controller/templates/helper.rb'
pull_file 'lib/generators/controller/templates/helper_test.rb'
pull_file 'lib/generators/controller/templates/view.html.erb'
pull_file 'lib/generators/model/USAGE'
pull_file 'lib/generators/model/model_generator.rb'
pull_file 'lib/generators/model/templates/model_spec.rb'
pull_file 'lib/generators/model/templates/model.rb'
pull_file 'lib/generators/model/templates/migration.rb'
pull_file 'lib/generators/model/templates/fixtures.yml'


# Miscellaneous initializers.
pull_file 'config/initializers/site_config.rb'
# Inject JQUERY_VERSION (defined above) into site_config.rb file.
gsub_file 'config/initializers/site_config.rb', /^JQUERY_VERSION =.*$/, "JQUERY_VERSION = '#{JQUERY_VERSION}'"


## Create a controller and route for the root/home page.
bundle
generate :controller, "home index"
route "map.root :controller => 'home'"
route "map.home '', :controller => 'home'"
pull_file 'app/views/home/index.html.erb'
pull_file 'app/controllers/home_controller.rb'


## Deployment configuration for Capistrano.
# TODO: cap deploy:setup should prompt for database name/user/password.
gem 'capistrano'
capify!
pull_file 'config/deploy.rb', force: true # TODO: Should modify this file instead of overriding it.
pull_file 'config/deploy/staging.rb'
pull_file 'config/deploy/production.rb'
# Create a config file for the staging environment that we added.
cp 'config/environments/production.rb', 'config/environments/staging.rb'
# Set the staging environment to display tracebacks when errors occur.
environment 'config.action_controller.consider_all_requests_local = true', :env => :staging

# Log database access to the console. From http://rubyquicktips.tumblr.com/post/379756937/always-turn-on-activerecord-logging-in-the-console
environment 'ActiveRecord::Base.logger = Logger.new(STDOUT) if "irb" == $0', :env => :development


# Create directory for temp files.
bundle
rake 'tmp:create'

# Git won't keep an empty directory around, so throw some .gitignore files in directories we want to keep around even if empty.
['tmp', 'log', 'vendor', 'test'].each do |dir|
  mkdir_p "#{dir}"
  touch "#{dir}/.gitignore"
end

# Create the database.
rake 'db:migrate' if activerecord


# Test the base app.
rake 'cucumber'
rake 'spec'
#rake 'spec:javascripts' # FIXME: Requires application.js to exist.

# TODO: These should be in the rake task that gets run by the git pre_commit hook.
#rake 'metrics:all' # Generate coverage, cyclomatic complexity, flog, flay, railroad, reek, roodi, stats... #FIXME: Not running properly.
run 'rake stats > doc/stats.txt'
run 'rake notes > doc/notes.txt'

# Set up .gitignore file. We load it from here, instead of using pull_file, because the template itself has its own .gitignore file.
create_file '.gitignore', <<END, force: true
# NOTE: We're NOT ignoring config/database.yml, because we're pulling the production passwords from a separate file.
.DS_Store
log/*.log
log/*.pid
tmp/**/*
db/schema.rb
db/*.sqlite3
db/*.db
doc/api
doc/app
vendor/**/.git
vendor/bundle/*
coverage/*
autotest_result.html
rerun.txt
features/rerun.txt
public/javascripts/*_[0-9]*.js
public/stylesheets/*_[0-9]*.css
public/attachments/*
END


# TODO: Set git pre-commit hook. FIXME: Need to define the rake task.
#file '.git/hooks/pre-commit', <<-END
#  #!/bin/sh
#  rake git:pre_commit
#END
#run 'chmod +x .git/hooks/pre-commit'


# Initialize submodules
git :submodule => 'init'

# Commit to git repository.
git :add => '.'
git :commit => "-a -m 'Initial commit'"

# TODO: Set git upstream repository. (Probably just print a reminder to do so.)
#git remote add origin ''
#git push origin master

# Make sure all the GEMs are installed on development system.
#rake 'gems:install'


puts <<END
NEXT STEPS:
    CD into the newly created Rails app.
    Edit the constants defined in the "config/initializers/site_config.rb" file.
    Make sure "rake spec" and "rake cucumber" run without errors.
    Make sure the app runs: "script/server".
    Commit changes: "git commit -a -m 'Basic site configuration.'"
    TODO: Create a new GIT branch for the new feature.
    Write feature ("script/generate feature feature_name") and feature steps.
    Run "rake cucumber". (FAILS)
    TODO: Add route.
    Write spec.
    Run "rake spec". (FAILS)
    Write code to pass spec.
    Run "rake spec". (PASSES)
    OPTIONAL: Commit the changes: "git commit -a -m 'Add blah for xyz feature.'"
    Refactor.
    Run "rake spec". (PASSES)
    OPTIONAL: Commit the changes: "git commit -a -m 'Refactor blah.'"
    Continue writing specs and code until feature is complete.
    Run "rake cucumber". (PASSES)
    TODO: Merge feature back into master branch.
    Make sure "rake spec" and "rake cucumber" still pass.
    OPTIONAL: Generate metrics: "rake metrics:all"
    Commit the new feature: "git commit -a -m 'Added xyz feature.'"
    Push to GitHub: "git push".
END
