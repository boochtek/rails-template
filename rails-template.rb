#!/bin/env ruby

# Rails template. Loads RSpec, Cucumber, DataMapper (optional), HAML, Sass, Slim, jQuery, etc.
# In many ways, this is a collection of my personal knowledge, opinions, and best practices regarding Rails.

# Copyright 2008,2009,2013 by BoochTek, LLC.
# Originally written by Craig Buchek.
# Released under MIT license (same as Ruby on Rails).


# Got some of these ideas and code from other templates, including http://github.com/jeremymcanally/rails-templates/ and http://github.com/ffmike/BigOldRailsTemplate/.


## Get user input, via environment variables or prompting the user.
datamapper = ENV['DATAMAPPER'] ? ENV['DATAMAPPER'] == 'y' : yes?('Include DataMapper?')
activerecord = ENV['ACTIVERECORD'] ? ENV['ACTIVERECORD'] == 'y' : yes?('Include ActiveRecord?')
mongoid = ENV['MONGOID'] ? ENV['MONGOID'] == 'y' : yes?('Include Mongoid?')
email = ENV['ACTIONMAILER'] ? ENV['ACTIONMAILER'] == 'y' : yes?('Include ActionMailer? (NOTE: ExceptionNotifier requires ActionMailer)')
devise = ENV['DEVISE'] ? ENV['DEVISE'] == 'y' : yes?('Use Devise and Warden for authentication?')
open_id = ENV['OPEN_ID'] ? ENV['OPEN_ID'] == 'y' : yes?('Use OpenID?')
hoptoad = ENV['HOPTOAD'] ? ENV['HOPTOAD'] == 'y' : yes?('Use HopToad Notifier?')
exception_notifier = ENV['EXCEPTIONNOTIFIER'] ? ENV['EXCEPTIONNOTIFIER'] == 'y' : yes?('Use Exception Notifier?')
email = true if exception_notifier || devise # Force email if we've enabled a plugin that requires it.


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
def pull_file(path)
  file "#{path}", open("#{RAILS_TEMPLATE_PATH}/#{path}").read
rescue
  puts "ERROR - Could not pull file."
  exit!
end


# Start a new GIT repository. Do this first, in case we want to install some GEMS as GIT submodules.
git :init


## DataMapper ORM.
# TODO: See what we can learn from http://github.com/jm/rails-templates/tree/master/datamapper.rb
if datamapper
  DM_VERSION = '~> 1.2'
  gem 'dm-rails',             version: DM_VERSION
  gem 'dm-sqlite-adapter',    version: DM_VERSION, groups: [:development, :test]
  gem 'dm-mysql-adapter',     version: DM_VERSION, groups: [:production, :staging]
  gem 'dm-postgres-adapter',  version: DM_VERSION
  gem 'dm-migrations',        version: DM_VERSION
  gem 'dm-types',             version: DM_VERSION
  gem 'dm-validations',       version: DM_VERSION
  gem 'dm-constraints',       version: DM_VERSION
  gem 'dm-transactions',      version: DM_VERSION
  gem 'dm-aggregates',        version: DM_VERSION
  gem 'dm-timestamps',        version: DM_VERSION
  gem 'dm-observer',          version: DM_VERSION
  generate 'dm_install' # install datamapper rake tasks
  pull_file 'lib/tasks/data_mapper.rb'
  puts "NOTE: For DataMapper models, use 'script/generate rspec_dm_model --skip-migration --skip-fixture' instead of 'script/generate rspec_model --skip-fixture'."
  puts "NOTE: Use 'rake db:auto_upgrade' to make your database schema match your DataMapper models."
end


## Optionally remove some portions of the standard Rails stack.

# ActiveRecord ORM.
if !activerecord
  environment 'config.frameworks -= [ :active_record ]'
end

# ActionMailer
if !email
  environment 'config.frameworks -= [ :action_mailer ]'
end


## Database config.
cp 'config/database.yml', 'config/database.yml.sample'
pull_file 'config/database.yml'

# Create databases. TODO: Is it OK to do this if not using DataMapper or ActiveRecord?
rake 'db:create:all'

if activerecord or mongoid
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

# Make sure we've got the rspec and cucumber GEMs loaded, before we run their generators.
rake 'gems:install' rescue puts 'Please run rake gems:install as root, to install gems locally on this computer.'

# Create spec directory structure.
generate 'rspec'
# Use the 'profile' format, to show 10 slowest specs. (Includes all the info the progress format does, as well.)
gsub_file 'spec/spec.opts', /--format progress/, '--format profile'


# Pull in RSpec support files and matchers.
# TODO: Should we try to put some of these in GEMs (see how Shoulda does it)?
pull_file 'spec/support/running.rb'
pull_file 'spec/support/require.rb'
pull_file 'spec/support/shoulda.rb'
pull_file 'spec/support/matchers/be_in.rb'
pull_file 'spec/support/matchers/be_sorted.rb'
pull_file 'spec/support/matchers/allow_values.rb'
pull_file 'spec/support/matchers/rails.rb'
pull_file 'spec/support/matchers/should_each.rb'


email_spec_helper.rb

# Create features directory for Cucumber, as well as a cucumber config file.
generate 'cucumber --rspec --capybara'
gsub_file 'config/cucumber.yml', /rerun\.txt/, 'features/rerun.txt' # Move the rerun flag file.
gsub_file 'config/cucumber.yml', /--strict/, '--guess' # Guess the right step to use when more than one matches.



# Allow use of FactoryGirl factories in Cucumber.
pull_file 'features/support/factory_girl.rb'
mkdir_p 'spec/factories'

# TODO: Create some commonly-used feature steps.

# Specs and steps for email.
if email
  gem 'email_spec', '~> 1.4', groups: ['test'] # See http://github.com/bmabey/email-spec for docs.
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


## Remove Prototype JavaScript stuff and use jQuery instead.
# Remove the Prototype files.
%w{prototype controls dragdrop effects}.each do |f|
  rm_f "public/javascripts/#{f}.js"
end
# Remove Prototype-using JavaScript from default Rails index page.
gsub_file 'public/index.html', /<script.*<\/script>/m, ''
# NOTE: We're leaving in ActionView::Helpers::JavaScriptHelper, ActionView::Helpers::PrototypeHelper, and ActionView::Helpers::ScriptaculousHelper. It'd be too difficult to extract them.

# jQuery for client-side scripting. NOTE: We inject JQUERY_VERSION into site_config.rb below.
JQUERY_VERSION = '2.0.2'
file "vendor/assets/javascripts/jquery-#{JQUERY_VERSION}.js", open("http://code.jquery.com/jquery-#{JQUERY_VERSION}.js").read
pull_file 'app/helpers/jquery_helper.rb'

# Pull in my custom JavaScript code.
pull_file 'public/javascripts/boochtek.js'
pull_file 'public/javascripts/boochtek/validation.js'
pull_file 'public/javascripts/boochtek/google-analytics.js'


## Error notification.
if hoptoad
  plugin 'hoptoad_notifier', :git => "git://github.com/thoughtbot/hoptoad_notifier.git", :submodule => true
  pull_file 'config/initializers/hoptoad.rb'
  # TODO: Prompt for and change host (default to 'hoptoadapp.com') and api_key config settings.
  # rake 'hoptoad:test'
end
if exception_notifier
  plugin 'exception_notifier', :git => 'git://github.com/rails/exception_notification.git', :submodule => true
end
pull_file 'app/controllers/application_controller.rb'


## Authentication
if devise
  # Devise and Warden.
  gem 'warden', :version => '0.9.7'
  gem 'devise', :version => '>= 1.0.5'
  gem 'bcrypt-ruby', :version => '>= 2.1.2'
  generate 'devise_install'
  generate 'devise User'
  # Using bcrypt is highly recommended. So we change the Devise configuration and the migration to use it.
  gsub_file 'config/initializers/devise.rb', /^.*config.encryptor =.*$/, 'config.encryptor = :bcrypt'
  gsub_file Dir.glob('db/migrate/*_devise_create_users.rb'), /t.authenticatable :encryptor => :sha1/, 't.authenticatable :encryptor => :bcrypt'
  puts 'NOTE: To use Devise, edit config/initializers/devise.rb, the generated User model, and the migration.'
  puts '  It is recommended to use bcrypt for encryption. (Change in the migration and initializer.)'
  puts '  After running the migration, you can use these in your controllers:'
  puts '    before_filter :authenticate_user!'
  puts '    user_signed_in?'
  puts '    current_user'
  puts '    user_session'
  puts '  In controller specs, include Devise::TestHelpers in ActionController::TestCase, then sign_in @user and sign_out @user.'
  puts '  In cucumber feature stories, '
end
if open_id
  # NOTE: We should probably use an OpenID strategy from within Warden and Devise instead of open_id_authentication. See http://blog.bitfluent.com/post/318173262/openid-strategy-for-warden for a good start, as well as http://groups.google.com/group/plataformatec-devise/browse_thread/thread/2dd6d14f59d21e83/f033896e83ac8b70.
  #gem 'ruby-openid' :lib => 'openid'
  #plugin 'open_id_authentication', :git => 'git://github.com/rails/open_id_authentication.git', :submodule => true
  #generate 'authenticated', 'user session' # Requires ActiveRecord.
  #rake 'db:sessions:create'
  #rake 'open_id_authentication:db:create'
end


## Authorization
#plugin 'role_requirement', :git => 'git://github.com/timcharper/role_requirement.git', :submodule => true
#generate 'roles', 'Role User'


## Formtastic and dependencies.
plugin 'validation_reflection', :git => 'http://github.com/redinger/validation_reflection.git', :submodule => true
plugin 'country-select', :git => 'http://github.com/rails/iso-3166-country-select.git', :submodule => true
plugin 'formtastic', :git => 'http://github.com/justinfrench/formtastic.git', :submodule => true
generate 'formtastic'
rm_f 'public/stylesheets/formtastic_changes.css' # I'll put my changes in the application.css file.


## My personal plugins.
plugin 'default_views', :git => "git://github.com/boochtek/rails-default_views.git", :submodule => true
plugin 'crud_actions', :git => "git://github.com/boochtek/rails-crud_actions.git", :submodule => true
plugin 'attribute_declarations', :git => 'git://github.com/boochtek/activerecord-attribute_declarations.git', :submodule => true


## Default HTML code.
# Default layout.
pull_file 'app/views/layouts/application.html.erb'
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
plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git', :submodule => true
rake 'asset:packager:create_yml' # TODO: Use/update the YAML file.
#gem 'hpricot', :source => 'http://code.whytheluckystiff.net'
#gem 'nokogiri'
#plugin 'http://svn.viney.net.nz/things/rails/plugins/acts_as_taggable_on_steroids', :submodule => true
#generate acts_as_taggable_migration
#plugin 'limerick_rake', :git => "git://github.com/thoughtbot/limerick_rake.git", :submodule => true
#plugin 'squirrel', :git => "git://github.com/thoughtbot/squirrel.git", :submodule => true
plugin 'ssl_requirement', :git => 'git://github.com/rails/ssl_requirement.git', :submodule => true
# USAGE: Add 'include SslRequirement' and 'ssl_required :action1, :action2' to controller (or ApplicationController).


# Footnotes at bottom of site when in development, with lots of info and links.
# TODO: Set up so we can use textmate links to edit files directly from web pages.
# TODO: Add more notes types. Notes on model methods, SQL table name/row-count/schema (info on each field).
gem 'rails-footnotes', :version => '~> 3.7', :env => [:development]
pull_file 'config/initializers/footnotes.rb'


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
generate :controller, "home index"
route "map.root :controller => 'home'"
route "map.home '', :controller => 'home'"
pull_file 'app/views/home/index.html.erb'
pull_file 'app/controllers/home_controller.rb'


## Deployment configuration for Capistrano.
# TODO: cap deploy:setup should prompt for database name/user/password.
gem 'capistrano'
capify!
pull_file 'config/deploy.rb'
pull_file 'config/deploy/staging.rb'
pull_file 'config/deploy/production.rb'
# Create a config file for the staging environment that we added.
cp 'config/environments/production.rb', 'config/environments/staging.rb'
# Set the staging environment to display tracebacks when errors occur.
environment 'config.action_controller.consider_all_requests_local = true', :env => :staging

# Log database access to the console. From http://rubyquicktips.tumblr.com/post/379756937/always-turn-on-activerecord-logging-in-the-console
environment 'ActiveRecord::Base.logger = Logger.new(STDOUT) if "irb" == $0', :env => :development


# Create directory for temp files.
rake 'tmp:create'

# Git won't keep an empty directory around, so throw some .gitignore files in directories we want to keep around even if empty.
['tmp', 'log', 'vendor', 'test'].each do |dir|
  mkdir_p "#{dir}"
  touch "#{dir}/.gitignore"
end

# Create the database.
rake 'db:automigrate' if datamapper
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
file '.gitignore', <<END
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
