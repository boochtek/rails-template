#!/bin/env ruby

# Rails template. Loads RSpec, Cucumber, HAML, Sass, Slim, jQuery, etc.
# In many ways, this is a collection of my personal knowledge, opinions, and best practices regarding Rails.

# Copyright 2008,2009,2013,2014 by BoochTek, LLC.
# Originally written by Craig Buchek.
# Released under MIT license (same as Ruby on Rails).


# Got some of these ideas and code from other templates, including:
#   * http://github.com/jeremymcanally/rails-templates/
#   * http://github.com/ffmike/BigOldRailsTemplate/


## Get user input, via environment variables or prompting the user.
ACTIVE_RECORD = ENV['ACTIVE_RECORD'] ? ENV['ACTIVE_RECORD'] == 'y' : yes?('Include ActiveRecord?')
AIRBRAKE = ENV['AIRBRAKE'] ? ENV['AIRBRAKE'] == 'y' : yes?('Use Airbrake Notifier?')
EXCEPTION_NOTIFIER = ENV['EXCEPTION_NOTIFIER'] ? ENV['EXCEPTION_NOTIFIER'] == 'y' : yes?('Use Exception Notifier?')
ACTION_MAILER = EXCEPTION_NOTIFIER || (ENV['ACTION_MAILER'] ? ENV['ACTION_MAILER'] == 'y' : yes?('Include ActionMailer?'))

if AIRBRAKE
  AIRBRAKE_API_KEY = ask('Airbrake API Key:')
end

if EXCEPTION_NOTIFIER
  EXCEPTION_NOTIFIER_SENDER = ENV['EXCEPTION_NOTIFIER_SENDER'] ? ENV['EXCEPTION_NOTIFIER_SENDER'] : ask('Send exception emails from (Name <address>):')
  EXCEPTION_NOTIFIER_RECIPIENTS = ENV['EXCEPTION_NOTIFIER_RECIPIENTS'] ? ENV['EXCEPTION_NOTIFIER_RECIPIENTS'] : ask('Send exception emails to (space-separated list):')
end


# Allow opening URLs as if they are local files.
require 'open-uri'

# Include FileUtils functionality. Note that we can't use include or define_method from within this app template file.
require 'fileutils'
def cp(src, dest, options = {}); FileUtils.cp(src, dest, options); end
def mv(src, dest, options = {}); FileUtils.mv(src, dest, options); end


## Decide whether to pull all the files from local directory, or from GitHub.
RAILS_TEMPLATE_PATH = File.dirname(rails_template)
if rails_template.match(%r{^/})
  running_local = true
else
  running_local = false
end
def source_paths
  [RAILS_TEMPLATE_PATH]
end

# Check to ensure that we can get to all the files we need.
begin
  open("#{RAILS_TEMPLATE_PATH}/rails-template.rb")
rescue
  raise 'You need to have an Internet connection for this template to work.'
end

# Ensure bundled gems are loaded into vendor/bundle.
bundle_command 'config --local path vendor/bundle'

# Don't allow Bundler to create binstubs. Rails wants to create its own binstubs.
bundle_command 'config --delete bin'

# Allow us to defer some actions until after all the gems have been bundled.
def after_bundle(&block)
  @after_bundle_blocks ||= []
  @after_bundle_blocks.append(block)
end

def run_bundle
  super
  @after_bundle_blocks.each do |block|
    block.call()
  end
end

after_bundle do
  rake 'rails:update:bin'
end


# Start a new GIT repository. Do this first, in case we want to install some GEMS as GIT submodules.
git :init


# Specify the version of Ruby we want to use. (Should work with RVM, rbenv, and chruby.)
create_file '.ruby-version', '2.1.3'


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
if ACTIVE_RECORD
  gem 'annotate', '~> 2.6', groups: [:development]
  after_bundle do
    generate 'annotate:install'
    rake 'db:create:all'
  end
else
  gsub_file 'config/application.rb', %r(^require "active_record/railtie"$), '#require "active_record/railtie"'
  ['development', 'test', 'production'].each do |env|
    gsub_file "config/environments/#{env}.rb", %r(^  config\.active_record\.), '  #config.active_record.'
  end
end

# ActionMailer
if !ACTION_MAILER
  gsub_file 'config/application.rb', %r(^require "action_mailer/railtie"$), '#require "action_mailer/railtie"'
  ['development', 'test', 'production'].each do |env|
    gsub_file "config/environments/#{env}.rb", %r(^  config\.action_mailer\.), '  #config.action_mailer.'
  end
end


## Database config.
mv 'config/database.yml', 'config/database.yml.sample'
copy_file 'config/database.yml'

if ACTIVE_RECORD
  # Use the Bullet gem to alert developers of unoptimized SQL queries.
  gem 'bullet', '~> 4.14', groups: [:development, :test]
  copy_file 'config/initializers/bullet.rb'
end


## Testing frameworks.
gem 'rspec',              '~> 3.1',   groups: ['development', 'test']
gem 'rspec-rails',        '~> 3.1',   groups: ['development', 'test']
gem 'bogus',              '~> 0.1.5', groups: ['test'] # Ensures that we don't stub/mock methods that don't exist.
gem 'database_cleaner',   '~> 1.3',   groups: ['test']
gem 'cucumber',           '~> 1.3',   groups: ['development', 'test']
gem 'cucumber-rails',     '~> 1.4',   groups: ['test'], require: false
gem 'capybara',           '~> 2.4',   groups: ['test']
gem 'factory_girl_rails', '~> 4.4',   groups: ['development', 'test']
gem 'shoulda',            '~> 3.5',   groups: ['test']
gem 'jasmine',            '~> 2.0',   groups: ['development', 'test']


after_bundle do
  # Create spec directory structure.
  generate 'rspec:install'

  # Pull in RSpec support files and matchers.
  # TODO: Should we try to put some of these in GEMs (see how Shoulda does it)?
  copy_file 'spec/support/running.rb'
  copy_file 'spec/support/require.rb'
  copy_file 'spec/support/shoulda.rb'
  copy_file 'spec/support/matchers/be_in.rb'
  copy_file 'spec/support/matchers/be_sorted.rb'
  copy_file 'spec/support/matchers/allow_values.rb'
  copy_file 'spec/support/matchers/rails.rb'
  copy_file 'spec/support/matchers/should_each.rb'


  # Create features directory for Cucumber, as well as a cucumber config file.
  generate 'cucumber:install'
  gsub_file 'config/cucumber.yml', /rerun\.txt/, 'features/rerun.txt' # Move the rerun flag file.
  gsub_file 'config/cucumber.yml', /--strict/, '--guess' # Guess the right step to use when more than one matches.


  # Allow use of FactoryGirl factories in Cucumber.
  copy_file 'features/support/factory_girl.rb'
  empty_directory 'spec/factories'
end


# TODO: Create some commonly-used feature steps for use in Cucumber.


# Background job processing.
gem 'sidekiq', '~> 3.2'


# Specs and steps for email.
if ACTION_MAILER
  gem 'email_spec', '~> 1.6', groups: ['test'] # See http://github.com/bmabey/email-spec for docs.
  after_bundle do
    generate 'email_spec:steps' # Generate email_steps.rb file.
    copy_file 'features/support/email_spec.rb' # Integration into Cucumber.
    copy_file 'spec/support/email_spec_helper.rb' # Integration into RSpec.
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
end

after_bundle do
  # Create spec/javascripts directory structure.
  generate 'jasmine:install'
  generate 'jasmine:examples'
end

## TODO: Create some sample specs and features that we can start with.
# NOTE: Be sure to make use of Shoulda RSpec matchers.
#       http://github.com/thoughtbot/shoulda/tree/master/lib/shoulda/active_record/matchers
#       http://github.com/thoughtbot/shoulda/tree/master/lib/shoulda/action_controller/matchers
# NOTE: Be sure to use the new syntax in features.
#         Background (like a Scenario section, but runs before each Scenario, and after the Before section).


## Stats and coverage tools.
gem 'metric_fu', '~> 4.11', groups: ['development', 'test']
after_bundle do
  append_file 'Rakefile', "require 'metric_fu'"
end

# Slim templating system.
gem 'slim-rails', '~> 2.1'

# HAML templating system.
gem 'haml', '~> 4.0'

# Sass CSS templating.
gem 'sass', '~> 3.4'


# jQuery for client-side scripting. NOTE: We inject JQUERY_VERSION into site_config.rb below.
JQUERY_VERSION = '2.1.1'
file "vendor/assets/javascripts/jquery-#{JQUERY_VERSION}.js", open("http://code.jquery.com/jquery-#{JQUERY_VERSION}.js").read
copy_file 'app/helpers/jquery_helper.rb'

# Pull in my custom JavaScript code.
copy_file 'public/javascripts/boochtek.js'
copy_file 'public/javascripts/boochtek/validation.js'
copy_file 'public/javascripts/boochtek/google-analytics.js'


## Error notification.
if AIRBRAKE
  gem 'airbrake'
  after_bundle do
    generate "airbrake --api-key #{AIRBRAKE_API_KEY}"
  end
end

if EXCEPTION_NOTIFIER
  gem 'exception_notification', '~> 4.0'
  after_bundle do
    generate 'exception_notification:install --sidekiq'
    gsub_file 'config/initializers/exception_notification.rb', /:email_prefix.*/, "email_prefix: '[#{app_name.classify}] ',"
    gsub_file 'config/initializers/exception_notification.rb', /:sender_address.*/, "sender_address: %{#{EXCEPTION_NOTIFIER_SENDER}},"
    gsub_file 'config/initializers/exception_notification.rb', /:exception_recipients.*/, "exception_recipients: %w[#{EXCEPTION_NOTIFIER_RECIPIENTS}]"
    # TODO: Add info on the current_user.
    #     Step 1: Add info to request.env["exception_notifier.exception_data"][:current_user] (probably in a before_filter in ApplicationController).
    #     Step 2: Create app/views/exception_notifier/_current_user.text.erb with the details from @current_user.
    #     Step 3: Add to email section of config: sections: ExceptionNotifier.sections + %w[current_user]
  end
end

copy_file 'app/controllers/application_controller.rb', force: true


## TODO: My personal plugins - default_views, crud_actions, attribute_declarations.


## Default HTML code.
# Default layout.
copy_file 'app/views/layouts/application.html.erb', force: true
# TODO: 404 and other files in public.

# Display a custom message when site is down for maintenance. From Advanced Rails Recipes #69.
# Use 'cap deploy:web:disable' to display the maintenance page, and 'cap deploy:web:enable' to return to normal service.
copy_file 'app/views/admin/maintenance.html.erb'
copy_file 'public/.htaccess'
copy_file 'config/deploy/maintenance.rb'

## Delete some unnecessary files.
remove_file 'README' # Needed for rake doc:rails for some reason.
remove_file 'doc/README_FOR_APP' # Needed for rake doc:app for some reason.
remove_file 'public/index.html'
remove_file 'public/images/rails.png'
#remove_file 'public/favicon.ico' # TODO: Really need to make sure favicon.ico is available, as browsers request it frequently.
#remove_file 'public/robots.txt'  # TODO: Add a robots.txt to ignore everything, so app starts in "stealth mode"? At least for staging?


## Default assets.
# Add some images used by the HTML, CSS, and JavaScript.
copy_file 'public/stylesheets/application.css'
copy_file 'public/images/invalid.gif'


## Other


# Footnotes at bottom of site when in development, with lots of info and links.
# TODO: Set up so we can use textmate links to edit files directly from web pages.
# TODO: Add more notes types. Notes on model methods, SQL table name/row-count/schema (info on each field).
gem 'rails-footnotes', '~> 4.1', groups: [:development]
after_bundle do
  generate 'rails_footnotes:install'
  copy_file 'lib/footnotes/current_user_note.rb'
  copy_file 'lib/footnotes/global_constants_note.rb'
  inject_into_file 'config/initializers/rails_footnotes.rb', after: "# ... other init code\n" do
    <<-'EOF'
      require 'footnotes/current_user_note'
      require 'footnotes/global_constants_note'
      Footnotes::Filter.notes -= [:general] # I don't see the point of this note.
      Footnotes::Filter.notes += [:current_user, :global_constants] # Add our custom note.
    EOF
  end
end


## My custom generators.
# copy_file 'lib/generators/controller/USAGE'
# copy_file 'lib/generators/controller/controller_generator.rb'
# copy_file 'lib/generators/controller/templates/controller_spec.rb'
# copy_file 'lib/generators/controller/templates/helper_spec.rb'
# copy_file 'lib/generators/controller/templates/controller.rb'
# copy_file 'lib/generators/controller/templates/functional_test.rb'
# copy_file 'lib/generators/controller/templates/helper.rb'
# copy_file 'lib/generators/controller/templates/helper_test.rb'
# copy_file 'lib/generators/controller/templates/view.html.erb'
# copy_file 'lib/generators/model/USAGE'
# copy_file 'lib/generators/model/model_generator.rb'
# copy_file 'lib/generators/model/templates/model_spec.rb'
# copy_file 'lib/generators/model/templates/model.rb'
# copy_file 'lib/generators/model/templates/migration.rb'
# copy_file 'lib/generators/model/templates/fixtures.yml'


# Miscellaneous initializers.
copy_file 'config/initializers/site_config.rb'
# Inject JQUERY_VERSION (defined above) into site_config.rb file.
gsub_file 'config/initializers/site_config.rb', /^JQUERY_VERSION =.*$/, "JQUERY_VERSION = '#{JQUERY_VERSION}'"


# Check to make sure Ruby garbage collection settings have been tuned.
copy_file 'config/initializers/check_gc.rb'


# Add some parameters to filter from logging.
append_file 'config/initializers/filter_parameter_logging.rb' do
  <<-'EOF'
    Rails.application.config.filter_parameters += [:password_confirmation, :confirm_password]
    Rails.application.config.filter_parameters += [:ssn, :social_security_number]
    Rails.application.config.filter_parameters += [:credit_card, :credit_card_number, :cvv, :cvv2]
  EOF
end

## Create a controller and route for the root/home page.
after_bundle do
  generate :controller, "home index"
end
route "root to: 'home#index', as: 'home'"
copy_file 'app/views/home/index.html.erb'
#copy_file 'app/controllers/home_controller.rb' # Already created by generate controller.


## App server.

# Use Unicorn in production and development by default.
gem 'unicorn', '~> 4.8'
gem 'rack-handlers', '~> 0.7'


## Deployment configuration for Capistrano.
# TODO: cap deploy:setup should prompt for database name/user/password.
gem 'capistrano', '~> 3.2'
after_bundle do
  capify!
  copy_file 'config/deploy.rb', force: true # TODO: Should modify this file instead of overriding it.
  copy_file 'config/deploy/staging.rb'
  copy_file 'config/deploy/production.rb'
  # Create a config file for the staging environment that we added.
  cp 'config/environments/production.rb', 'config/environments/staging.rb'
  # Give cucumber the same settings as test.
  cp 'config/environments/test.rb', 'config/environments/cucumber.rb'
  # Set the staging environment to display tracebacks when errors occur.
  environment 'config.action_controller.consider_all_requests_local = true', env: :staging
end

# Log database access to the console. From http://rubyquicktips.tumblr.com/post/379756937/always-turn-on-activerecord-logging-in-the-console
environment 'ActiveRecord::Base.logger = Logger.new(STDOUT) if "irb" == $0', env: :development


# Create directory for temp files.
after_bundle do
  rake 'tmp:create'
end

# Git won't keep an empty directory around, so throw some .keep files in directories we want to keep around even if empty.
%w[tmp log vendor test doc].each do |dir|
  keep_file dir
end

# Create the database.
after_bundle do
  rake 'db:migrate' if ACTIVE_RECORD
end

# Test the base app.
after_bundle do
  run 'cucumber'
  run 'rspec'
  #rake 'spec:javascripts' # FIXME: Requires application.js to exist.

  # TODO: These should be in the rake task that gets run by the git pre_commit hook.
  #rake 'metrics:all' # Generate coverage, cyclomatic complexity, flog, flay, railroad, reek, roodi, stats... #FIXME: Not running properly.

  run 'rake stats > doc/stats.txt'
  run 'rake notes > doc/notes.txt'
end


# Set up .gitignore file. We load it from here, instead of using copy_file, because the template itself has its own .gitignore file.
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
bin/*
.bundle/config
.env*
END


# TODO: Set git pre-commit hook. FIXME: Need to define the rake task.
#file '.git/hooks/pre-commit', <<-END
#  #!/bin/sh
#  rake git:pre_commit
#END
#run 'chmod +x .git/hooks/pre-commit'


after_bundle do
  # Initialize submodules
  git submodule: 'init'

  # Commit to git repository.
  git add: '.'
  git commit: "-a -m 'Initial commit'"

  # TODO: Set git upstream repository. (Probably just print a reminder to do so.)
  #git remote add origin ''
  #git push origin master
end

after_bundle do
  puts <<-END
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
end
