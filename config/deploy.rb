# NOTE: Some settings are defined in config/deploy/*.rb files.
# Usage:
#   cap deploy:setup ;# Create shared and releases directories in /var/www/sitename/.
#   Edit your /var/www/YOURAPPNAME.com/shared/config/database.yml file with your database, username, password, and socket.
#   cap deploy:cold ;# First time only.
#   cap deploy:migrations ;# Any other time, if migrations need to be run during the deploy.
#   cap deploy ;# Any other time, if no migrations are required.
#   cap deploy:migrate ;# Run migrations manually.
#   Set Apache's DocumentRoot /var/www/SITENAME/current/public

# If we don't specify the deploy environment, assume staging.
set :default_stage, 'staging'

# We want to be able to deploy to staging and production environments.
# NOTE: You'll need a config/deploy/*.rb file for each deploy environment.
set :stages, %w(staging production)
require 'capistrano/ext/multistage'

# The name of the application, used in directory names.
set :application, 'NAME_OF_APPLICATION'

# Define short names of servers we'll be deploying to.
set :prod_server, 'SERVER.TO.DEPLOY.TO'

# Set SSH port, in case we use a non-standard port.
set :port, 22

# Define the Subversion repository.
set :scm, :svn
set :repository,  "svn+ssh://#{prod_server}/var/svn/#{application}/trunk"

# Define a GIT repository.
#set :scm, :git
#set :repository,  "git@github.com:GITHUBUSERNAME/GITHUBREPOSITORYNAME.git"
#set :git_enable_submodules, 1         # Make sure git submodules are populated

# Don't use sudo - run the startup scripts as myself. If we've set up the directory as sticky, with proper group ownership, this should work.
set :use_sudo, false

# Define the top-level directory into which to deploy.
set :deploy_to, "/var/www/#{site_name}"

namespace :deploy do
  desc 'Restart Application (using Phusion Passenger)'
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc 'Make symlink for database.yml'
  task :symlink_database_yaml do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml" 
  end

  desc "Create empty database.yml in shared path" 
  task :create_database_yaml do
    run "mkdir -p #{shared_path}/config" 
    put '', "#{shared_path}/config/database.yml" 
  end

  desc "Package up asset files - compress JavaScript and CSS files into a single file for each"
  task :package_assets do
    run "cd #{current_path}"
    run "rake asset:packager:build_all"
  end
end
after 'deploy:setup', 'deploy:create_database_yaml'
after 'deploy:update_code', 'deploy:symlink_database_yaml'
after 'deploy:update_code', 'deploy:package_assets'
after 'deploy', 'deploy:cleanup' # Leaves current deployment, plus the 4 previous.
after 'deploy:migrations', 'deploy:cleanup'
