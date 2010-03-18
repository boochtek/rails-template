#!/bin/env ruby

# Rails template. Loads RSpec, Cucumber, DataMapper (optional), HAML, jQuery, etc.
# In many ways, this is a collection of my personal knowledge, opinions, and best practices regarding Rails.

# Copyright 2008,2009 by BoochTek, LLC.
# Originally written by Craig Buchek.
# Released under MIT license (same as Ruby on Rails).


# Got some of these ideas and code from other templates, including http://github.com/jeremymcanally/rails-templates/ and http://github.com/ffmike/BigOldRailsTemplate/.


## Get user input, via environment variables or prompting the user.
rails_submodule = ENV['SUBMODULE'] ? (ENV['SUBMODULE'] == 'y') : yes?('Pull in Rails as a GIT sub-module?')
datamapper = ENV['DATAMAPPER'] ? ENV['DATAMAPPER'] == 'y' : yes?('Include DataMapper?')
activerecord = ENV['ACTIVERECORD'] ? ENV['ACTIVERECORD'] == 'y' : yes?('Include ActiveRecord?')
activeresource = ENV['ACTIVERESOURCE'] ? ENV['ACTIVERESOURCE'] == 'y' : yes?('Include ActiveResource?')
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
if template.match(%r{^/}) and File.exists?(template)
  RAILS_TEMPLATE_PATH = File.dirname(template)
  running_local = true
elsif File.exists?(File.join(ENV['PWD'], template)) # Dir.getwd is the Rails root, so we have to find what it was when the 'rails' command was run.
  RAILS_TEMPLATE_PATH = File.dirname(File.join(ENV['PWD'], template))
  running_local = true
else
  RAILS_TEMPLATE_PATH = 'http://github.com/boochtek/rails-template/raw/master'
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


# Pull in a copy of Rails as a GIT submodule.
if rails_submodule
  git "submodule add git://github.com/rails/rails.git vendor/rails"
end


## DataMapper ORM.
# TODO: See what we can learn from http://github.com/jeremymcanally/rails-templates/tree/master/datamapper.rb
if datamapper
  gem 'addressable', :lib => 'addressable/uri'
  gem 'data_objects', :version => '0.10.1'
  gem 'do_sqlite3', :version => '0.10.1.1', :env => [:development, :test]
  gem 'do_mysql', :version => '0.10.1', :env => [:production, :staging]
  gem 'dm-core', :version => '0.10.2'
  gem 'dm-migrations', :version => '0.10.2'
  gem 'dm-validations', :version => '0.10.2'
  gem 'dm-timestamps', :version => '0.10.2'
  #gem 'dm-transaction', :version => '0.10.2' # For testing, if/when it gets separated from dm-core; see first line of dm-core/transaction.rb or http://blog.teksol.info/2008/10/17/how-to-use-datamapper-with-rails-part-2
  gem 'rails_datamapper', :version => '0.10.2'
  config.plugins = [ :rails_datamapper, :all ] # Make datamapper load first as some plugins have dependencies on it.
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

# ActiveResource
if !activeresource
  environment 'config.frameworks -= [ :active_resource ]'
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

# Use the Bullet gem to alert developers of unoptimized SQL queries.
gem 'bullet', :version => '>= 1.7.6', :env => [:development, :test]
pull_file 'config/initializers/bullet.rb'


## Testing frameworks.
# NOTE: Using :lib => false on these, as Rails doesn't need to load them. See http://wiki.github.com/dchelimsky/rspec/configgem-for-rails/.
# TODO: Do we need to tell rspec/cucumber to use shoulda and factory_girl?
# NOTE: Rails (2.3.2, at least) places the config.gem statements in the reverse order that we specify them here.
gem 'rspec', :lib => false, :version => '>= 1.3.0'
gem 'rspec-rails', :lib => false, :version => '>= 1.3.2'
gem 'cucumber', :lib => false, :version => '>= 0.6.3'
gem 'webrat', :lib => false, :version => '>= 0.7.0'
gem 'thoughtbot-shoulda', :lib => 'shoulda', :version => '>= 2.10.1', :source => 'http://gems.github.com' # FIXME: Really want 3.0+ for complete RSpec integration.
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :version => '>= 1.2.2', :source => 'http://gems.github.com'
gem 'rr', :lib => 'rr', :version => '>= 0.10.10'
# TODO: Only install this if Java is installed on the dev box.
plugin 'blue-ridge', :git => 'git://github.com/relevance/blue-ridge.git', :submodule => true # NOTE: Requires Java to run the tests. Run 'rake spec:javascripts' to run tests.

# Make sure we've got the rspec and cucumber GEMs loaded, before we run their generators.
rake 'gems:install' rescue puts 'Please run rake gems:install as root, to install gems locally on this computer.'

# Create spec directory structure.
generate 'rspec'
# Use the 'profile' format, to show 10 slowest specs. (Includes all the info the progress format does, as well.)
gsub_file 'spec/spec.opts', /--format progress/, '--format profile'


# Pull in RSpec helpers from a subdirectory. TODO: Should we divide these into options, matchers, and helpers?
# TODO: Should we try to put some of these in GEMs (see how Shoulda does it)?
run 'echo "Dir.glob(File.join(Dir.pwd, \'helpers/**/*.rb\')).each { |file| require file }" >> spec/spec_helper.rb'
pull_file 'spec/helpers/rr.rb'
pull_file 'spec/helpers/should_each.rb'
pull_file 'spec/helpers/its.rb'
pull_file 'spec/helpers/running.rb'
pull_file 'spec/helpers/be_in.rb'
pull_file 'spec/helpers/be_sorted.rb'
pull_file 'spec/helpers/allow_values.rb'
pull_file 'spec/helpers/require.rb'
pull_file 'spec/helpers/rails.rb'

# Create feature directory for Cucumber.
mkdir_p 'features'

# Allow use of FactoryGirl factories in Cucumber. FIXME: Doesn't work.
#run 'echo "require \"#{Rails.root}/spec/factories\"" >> features/support/env.rb'
#mkdir_p 'spec/factories'

# TODO: Create some commonly-used feature steps.

# Specs and steps for email. FIXME: Not working.
if email
#  plugin 'email-spec', :git => 'git://github.com/bmabey/email-spec.git', :submodule => true
#  append_file 'features/support/env.rb', "require 'email_spec/cucumber'"
#  generate email_spec # TODO: Not sure if I should do this here, or if it's like generating a feature.
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

# Create spec/javascripts directory structure. TODO: Write some sample tests. See http://github.com/relevance/blue-ridge/ for details.
generate 'blue_ridge'

## TODO: Create some sample specs and features that we can start with.
# NOTE: Be sure to make use of Shoulda RSpec matchers.
#       http://github.com/thoughtbot/shoulda/tree/master/lib/shoulda/active_record/matchers
#       http://github.com/thoughtbot/shoulda/tree/master/lib/shoulda/action_controller/matchers
# NOTE: Be sure to use the new syntax in features.
#         Background (like a Scenario section, but runs before each Scenario, and after the Before section).


## Stats and coverage tools.
gem 'flay'
gem 'flog'
gem 'reek'
gem 'roodi'
gem 'chronic'
gem 'jscruggs-metric_fu', :version => '1.0.2', :lib => 'metric_fu', :source => 'http://gems.github.com'
append_file 'Rakefile', "require 'metric_fu'"


# HAML templating system.
gem 'haml', :version => '>= 2.2.21'
run 'haml --rails .'


## Remove Prototype JavaScript stuff and use jQuery instead.
# Remove the Prototype files.
%w{prototype controls dragdrop effects}.each do |f|
  rm_f "public/javascripts/#{f}.js"
end
# Remove Prototype-using JavaScript from default Rails index page.
gsub_file 'public/index.html', /<script.*<\/script>/m, ''
# NOTE: We're leaving in ActionView::Helpers::JavaScriptHelper, ActionView::Helpers::PrototypeHelper, and ActionView::Helpers::ScriptaculousHelper. It'd be too difficult to extract them.

# jQuery for client-side scripting. NOTE: We inject JQUERY_VERSION into site_config.rb below.
JQUERY_VERSION = '1.4.2'
file "public/javascripts/jquery-#{JQUERY_VERSION}.js", open("http://code.jquery.com/jquery-#{JQUERY_VERSION}.js").read
pull_file 'app/helpers/jquery_helper.rb'


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
  gem 'warden', :version => '>= 0.9.7'
  gem 'devise', :version => '>= 1.0.4'
  gem 'bcrypt-ruby', :version => '>= 2.1.2', :lib => 'bcrypt'
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
generate 'formtastic_stylesheets'
rm_f 'public/stylesheets/formtastic_changes.css'


## My personal plugins.
plugin 'default_views', :git => "git://github.com/boochtek/rails-default_views.git", :submodule => true
plugin 'crud_actions', :git => "git://github.com/boochtek/rails-crud_actions.git", :submodule => true


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
# TODO: Set up so we can use textmate links to edit files (preferably in $VISUAL or Komodo) directly from web pages.
# TODO: Add more notes types. Notes on model methods, SQL table name/row-count/schema (info on each field).
plugin 'rails-footnotes', :git => 'http://github.com/josevalim/rails-footnotes.git', :submodule => true
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
['tmp', 'log', 'vendor', 'test', 'features'].each do |dir|
  mkdir_p "#{dir}"
  touch "#{dir}/.gitignore"
end

# Create the database.
rake 'db:automigrate' if datamapper
rake 'db:migrate' if activerecord


# Test the base app.
run 'cucumber'
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
    Make sure "rake spec" and "cucumber" run without errors.
    Make sure the app runs: "script/server".
    Commit changes: "git commit -a -m 'Basic site configuration.'"
    TODO: Create a new GIT branch for the new feature.
    Write feature ("script/generate feature feature_name") and feature steps.
    Run "cucumber". (FAILS)
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
    Run "cucumber". (PASSES)
    TODO: Merge feature back into master branch.
    Make sure "rake spec" and "cucumber" still pass.
    OPTIONAL: Generate metrics: "rake metrics:all"
    Commit the new feature: "git commit -a -m 'Added xyz feature.'"
    Push to GitHub: "git push".
END
