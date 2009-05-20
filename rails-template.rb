#!/bin/env ruby

# Rails template. Links to local copy of Edge Rails, if available. Loads DataMapper, HAML, jQuery, jRails, etc.
# In many ways, this is a collection of my personal knowledge, opinions, and best practices regarding Rails.

# Got some of these ideas and code from other templates, including http://github.com/jeremymcanally/rails-templates/.

# FIXME: rake gems:install no longer works if any initializers are added. There's a dependency loop somewhere.

# TODO: Allow a way to pass in configuration decisions.
#         Will allow scripted testing.
# TODO: Testing.
#         Create a test Rails instance, and see if it works.
#         Need to create a Rakefile.
# TODO: Pull in BaseHTML stuff.
# TODO: Add generators for models, controllers, and views.
#         Use my own code in place of Rails defaults.
#         Use rspec, shoulda, rr.
# TODO: Figure out what to do about GEM version numbers.
#         Should we be using git submodules, and pulling straight from github?
#             I'd rather use shared system GEMs.
# TODO: Make sure we have a Rails layout and a favicon.
#         Make sure app will run "out of the box" without errors or missing files.
# TODO: Need to be able to specify GEMs that are only needed for development, not deployment.
#         Will :lib => false work?
# TODO: Add more plugins:
#         Metrics_fu, and its dependencies.
#         Automated validations, pulled from DB (DrySQL, Magic???, validation_reflection (valirefl), ???)
#         Auto-migrations?
#         Annotate-models or ColumnComments. (Only if AR is enabled.)
#         jRails (maybe, or just use hand-written jQuery) - probably include it just in case.
#         Machinist (fork that handles DM), FactoryGirl (leaning more toward this now)
#         AuthLogic, Clearance, RPX (leaning towards this -- outsource authentication to an external source)
#         Allow SVN instead of GIT. (Still pull from GIT, but use SVN after that.)
# TODO: jQuery functionality
#         Disable submit buttons when clicked.
#         Column sorting.
#         Pagination.


# Allow opening URLs as if they are local files.
require 'open-uri'


## Decide whether to pull all the files from local directory, or from GitHub.
if File.exists?(Dir.getwd + '/../rails-template.rb')
  RAILS_TEMPLATE_PATH = '..'
else
  RAILS_TEMPLATE_PATH = 'http://github.com/boochtek/rails-template/raw/master'
end


# Check to ensure that we can get to all the files we need.
begin
  open("#{RAILS_TEMPLATE_PATH}/rails-template.rb")
rescue 
  raise 'You need to have an Internet connection for this template to work.'
end


# Check that we can sudo to root, and cache the credentials up front.
# TODO: Use sudo conditionally later on, depending on the result here.
can_sudo = ((run 'sudo echo testing sudo') == 'testing sudo')
puts 'You may need to be able to use sudo to install gems.' unless can_sudo


# Make it easy to pull files from the template repository into the project.
def pull_file(path)
  file "#{path}", open("#{RAILS_TEMPLATE_PATH}/#{path}").read
end


# Start a new GIT repository. Do this first, in case we want to install some GEMS as GIT externals/submodules.
git :init


# Pull in a copy of Rails, either from GitHub (as a submodule), or from a local copy.
if yes?('Pull in Rails as a GIT sub-module?')
  git "submodule add git://github.com/rails/rails.git vendor/rails"
elsif ask('Link to local copy of Rails Edge?')
  # TODO: Guess and/or prompt for RAILS_EDGE_DIR
  RAILS_EDGE_DIR = File.expand_path('~/Work/projects/rails-edge')
  run "ln -s #{RAILS_EDGE_DIR} vendor/rails" if File.exists?(RAILS_EDGE_DIR)
end


## Delete some unnecessary files.
run 'rm README' # Needed for rake doc:rails for some reason.
run 'rm doc/README_FOR_APP' # Needed for rake doc:app for some reason.
#run 'rm public/index.html'  # FIXME: Need a default route before deleting this.
#run 'rm public/favicon.ico' # TODO: Really need to make sure favicon.ico is available, as browsers request it frequently.
#run 'rm public/images/rails.png'
#run 'rm public/robots.txt'  # TODO: Add a robots.txt to ignore everything, so app starts in "stealth mode"? At least for staging?


## DataMapper ORM.
# TODO: See what we can learn from http://github.com/jeremymcanally/rails-templates/tree/master/datamapper.rb
if (datamapper = yes?('Include DataMapper?'))
  gem 'addressable', :lib => 'addressable/uri'
  gem 'data_objects', :version => '0.9.11'
  gem 'do_sqlite3', :version => '0.9.11'  # if ['development', 'test'].include?(Rails.env)    # Rails and RAILS_ENV not yet defined here.
  gem 'do_mysql', :version => '0.9.11'    # if ['production', 'staging'].include?(Rails.env)
  gem 'dm-core', :version => '0.9.11'
  gem 'dm-migrations', :version => '0.9.11'
  gem 'dm-validations', :version => '0.9.11'
  gem 'dm-timestamps', :version => '0.9.11'
  #gem 'dm-transaction', :version => '0.9.11' # For testing, if/when it gets separated from dm-core; see first line of dm-core/transaction.rb or http://blog.teksol.info/2008/10/17/how-to-use-datamapper-with-rails-part-2
  # Not sure if I should be using rails_datamapper or datamapper4rails.
  gem 'rails_datamapper', :version => '0.9.11' # FIXME: Not a valid gem at this point; have to pull manually from GitHub datamapper/dm-more.
  #gem "datamapper4rail", :lib => 'datamapper4rails' # work around the typo
  # Make datamapper load first as some plugins have dependencies on it  
  config.plugins = [ :rails_datamapper, :all ]
  generate 'dm_install' # install datamapper rake tasks
  pull_file 'lib/tasks/data_mapper.rb'
  puts "NOTE: For DataMapper models, use 'script/generate rspec_dm_model --skip-migration --skip-fixture' instead of 'script/generate rspec_model --skip-fixture'."
  puts "NOTE: Use 'rake db:auto_upgrade' to make your database schema match your DataMapper models."
end


## Optionally remove some portions of the standard Rails stack.

# ActiveRecord ORM.
# TODO: Make sure this actually works.
if !(activerecord = yes?('Include ActiveRecord?'))
  initializer 'no_active_record.rb', <<-END
    Rails::Initializer.run do |config|
      config.frameworks -= [ :active_record ]
    end
  END
end

# ActiveResource
if !yes?('Include ActiveResource?')
  initializer 'no_active_resource.rb', <<-END
    Rails::Initializer.run do |config|
      config.frameworks -= [ :active_resource ]
    end
  END
end

# ActionMailer
if !(email = yes?('Include ActionMailer?'))
  initializer 'no_action_mailer.rb', <<-END
    Rails::Initializer.run do |config|
      config.frameworks -= [ :action_mailer ]
    end
  END
end


## Database config.
run "cp config/database.yml config/database.yml.sample"
pull_file 'config/database.yml'

# Create databases.
rake 'db:create:all'


## Testing frameworks.
# NOTE: Using :lib => false on these, as Rails doesn't need to load them. See http://wiki.github.com/dchelimsky/rspec/configgem-for-rails/.
# TODO: Do we need to tell rspec/cucumber to use shoulda and factory_girl?
gem 'rspec', :lib => false, :version => '>= 1.2.2'
gem 'rspec-rails', :lib => false, :version => '>= 1.2.2'
gem 'cucumber', :lib => false, :version => '>= 0.2.0'
gem 'webrat', :lib => false, :version => '>= 0.4.3'
gem 'thoughtbot-shoulda', :lib => 'shoulda', :version => '>= 2.10.1', :source => 'http://gems.github.com' # FIXME: Really want 3.0+ for complete RSpec integration.
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem 'rr', :lib => 'rr', :version => '>= 0.8.1'
plugin 'blue-ridge', :git => 'git://github.com/relevance/blue-ridge.git' # NOTE: Requires Java to run the tests. Run 'rake spec:javascripts' to run tests.

# Make sure we've got the rspec and cucumber GEMs loaded, before we run their generators.
rake 'gems:install', :sudo => true

# Create spec directory structure.
generate 'rspec'

# Create feature directory structure.
generate 'cucumber'

# Create spec/javascripts directory structure. TODO: Write some sample tests. See http://github.com/relevance/blue-ridge/ for details.
generate 'blue_ridge'


# NOTE: Be sure to use the new syntax in features.
#         Background (like a Scenario section, but runs before each Scenario, and after the Before section).
#run 'mkdir -p spec/options spec/matchers'
#run 'echo "require spec/matchers/*" >> spec/spec_helper.rb' ;# FIXME: Do this the right way.
#run 'echo "require spec/options/*" >> spec/spec_helper.rb' ;# FIXME: Do this the right way.
# TODO: Add all my custom matchers. TODO: Should really put them in a GEM, if possible (see how Shoulda does it).
# TODO: Make use of Shoulda RSpec matchers.
#       http://github.com/thoughtbot/shoulda/tree/master/lib/shoulda/active_record/matchers
#       http://github.com/thoughtbot/shoulda/tree/master/lib/shoulda/action_controller/matchers

# TODO: Figure out a better way to do this. Probably create spec/spec_helpers/*.
run 'echo "require \'rr\'" >> spec/spec_helper.rb'
run 'echo "Spec::Runner.configure do |config| {config.mock_with :rr}" >> spec/spec_helper.rb'


## Stats and coverage tools.
gem 'flay'
gem 'flog'
gem 'reek'
gem 'roodi'
gem 'chronic'
gem 'jscruggs-metric_fu', :version => '1.0.2', :lib => 'metric_fu', :source => 'http://gems.github.com'
run 'echo "require \'metric_fu\'" >> Rakefile'


# HAML templating system.
gem 'haml', :version => '>= 2.0.6'
run 'haml --rails .'


# Remove Prototype JavaScript stuff.
# TODO: Specify the exact files to delete.
run 'rm public/javascripts/*.js' # Remove Prototype files.
#TODO: Remove Prototype junk from ActionView::Helpers::JavaScriptHelper and ActionView::Helpers::PrototypeHelper, and scriptaculous_helper.


# jQuery for client-side scripting. TODO: The JQUERY_VERSION is duplicated in site_config.rb file.
JQUERY_VERSION = '1.3.2'
# TODO: Can we replace the code below with something like our open-uri code?
run "curl -L http://jqueryjs.googlecode.com/files/jquery-#{JQUERY_VERSION}.js > public/javascripts/jquery-#{JQUERY_VERSION}.js"
#gem 'jrails'



## Error notification.
if yes?('Use HopToad Notifier?')
  plugin 'hoptoad_notifier', :git => "git://github.com/thoughtbot/hoptoad_notifier.git"
  file 'config/initializer/hoptoad.rb', open("#{RAILS_TEMPLATE_PATH}/config/initializer/hoptoad.rb").read
  # FIXME/TODO: Need to add 'include HoptoadNotifier::Catcher' to ApplicationController.
  # TODO: Prompt for and change host (default to 'hoptoadapp.com') and api_key config settings.
  rake 'hoptoad:test'
elsif yes?('Use Exception Notifier?')
  plugin 'exception_notifier', :git => 'git://github.com/rails/exception_notification.git'
  # FIXME/TODO: Need to add 'include ExceptionNotifiable' to ApplicationController.  
end
# TODO: Perhaps add the following to ApplicationController:
# if const_defined?('HoptoadNotifier')
#   include HoptoadNotifier::Catcher
# elsif const_defined?('ExceptionNotifiable')
#   include ExceptionNotifiable


## Authentication/authorization
# TODO: Ask which one to use. Proably want to default to using OpenID at "login.#{my_domain}".
#plugin 'restful-authentication', :git => 'git://github.com/technoweenie/restful-authentication.git'
#plugin 'role_requirement', :git => 'git://github.com/timcharper/role_requirement.git'
#gem 'ruby-openid' :lib => 'openid'
#plugin 'open_id_authentication', :git => 'git://github.com/rails/open_id_authentication.git'
#generate 'authenticated', 'user session' # Required ActiveRecord.
#generate 'roles', 'Role User'
#rake 'db:sessions:create'
#rake 'open_id_authentication:db:create'


# TODO: Might be easier to use as a plugin for now.
#gem 'boochtek-rails-crud_actions', :lib => 'rails-crud_actions', :source => 'http://gems.github.com' # Or gem 'rails-crud_actions', :git => "git://github.com/boochtek/rails-crud_actions.git"


## Other
plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git'
rake 'asset:packager:create_yml' # TODO: Use/update the YAML file.
#gem 'hpricot', :source => 'http://code.whytheluckystiff.net'
#gem 'nokogiri'
#plugin 'http://svn.viney.net.nz/things/rails/plugins/acts_as_taggable_on_steroids'
#generate acts_as_taggable_migration
#plugin 'limerick_rake', :git => "git://github.com/thoughtbot/limerick_rake.git"
#plugin 'squirrel', :git => "git://github.com/thoughtbot/squirrel.git"


# Footnotes at bottom of site when in development, with lots of info and links.
# TODO: Set up so we can use textmate links to edit files (preferably in $VISUAL or Komodo) directly from web pages.
# FIXME: Not working; try drnic version.
# TODO: Add more notes types. Info on the current user would be great.
plugin 'rails-footnotes', :git => 'http://github.com/josevalim/rails-footnotes.git'



## Default HTML code.
# Default layout.
pull_file 'app/views/layouts/application.html.erb'
# TODO: 404 and other files in public.

# Display a custom message when site is down for maintenance. From Advanced Rails Recipes #69.
# Use 'cap deploy:web:disable' to display the maintenance page, and 'cap deploy:web:enable' to return to normal service.
pull_file 'app/views/admin/maintenance.html.erb'
pull_file 'public/.htaccess'
pull_file 'config/deploy/maintenance.rb'


# Miscellaneous initializers.
pull_file 'config/initializers/site_config.rb'


## Deployment configuration for Capistrano.
# TODO: cap deploy:setup should prompt for database name/user/password.
gem 'capistrano'
pull_file 'config/deploy.rb'
pull_file 'config/deploy/staging.rb'
pull_file 'config/deploy/production.rb'
# Create a config file for the staging environment that we added.
run 'cp config/environments/production.rb config/environments/staging.rb'
# Set the staging environment to display tracebacks when errors occur.
run "sed -i config/environments/staging.rb -e 's/config.action_controller.consider_all_requests_local = false/config.action_controller.consider_all_requests_local = true/'"
capify!



# Create directory for temp files.
rake 'tmp:create'

# Git won't keep an empty directory around, so throw some .gitignore files in directories we want to keep around even if empty.
['tmp', 'log', 'vendor', 'test'].each do |dir|
  run "mkdir -p #{dir}"
  run "touch #{dir}/.gitignore"
end

# Create the database.
rake 'db:automigrate' if datamapper
rake 'db:migrate' if activerecord


# Test the base app.
rake 'features'
rake 'spec'
#rake 'spec:javascripts' # FIXME: Requires application.js to exist.

# TODO: These should be in the rake task that gets run by the git pre_commit hook.
#rake 'metrics:all' # Generate coverage, cyclomatic complexity, flog, flay, railroad, reek, roodi, stats... #FIXME: Not running properly.
run 'rake stats > doc/stats.txt'
run 'rake notes > doc/notes.txt'

# Set up .gitignore file.
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
END


# TODO: Set git pre-commit hook. FIXME: Need to define the rake task.
#file '.git/hooks/pre-commit', <<-END
#  #!/bin/sh
#  rake git:pre-commit
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
#rake 'gems:install', :sudo => true


puts <<END
NEXT STEPS:
    CD into the newly created Rails app.
    Edit the constants defined in the "config/initializers/site_config.rb" file.
    Commit changes: "git commit -a -m 'Basic site configuration.'"
    TODO: Create a new GIT branch for the new feature.
    Make sure "rake spec" and "rake features" run without errors.
    Make sure the app runs: "script/server".
    Write feature ("script/generate feature feature_name") and feature steps.
    Run "rake features". (FAILS)
    TODO: Add routes.
    Write spec.
    Run "rake spec". (FAILS)
    Write code to pass spec.
    Run "rake spec". (PASSES)
    Refactor.
    Run "rake spec". (PASSES)
    Contine writing specs and code until feature is complete.
    Run "rake features". (PASSES)
    TODO: Merge feature back into master branch.
    Make sure "rake spec" and "rake features" still pass.
    Commit the new feature: "git commit -a -m 'Added xyz feature.'"
    Push to GitHub: "git push".
END
