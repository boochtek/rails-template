# Define stage for use in main config/deploy.rb file.
set :stage, 'staging'

# Set the directory to deploy files to.
# NOTE: This directory will have subdirectories: releases, current (soft link), shared.
set :deploy_to, "/var/www/#{application}/#{stage}"

# Set the roles that each machine will play.
#role :app, "#{prod_server}", :port => 1776, :user => 'craigb'
#role :web, "#{prod_server}", :port => 1776, :user => 'craigb'
server "#{prod_server}", :app, :web, :port => 1776, :user => 'craigb'
role :db,  "#{prod_server}", :primary => true, :port => 1776, :user => 'craigb'
