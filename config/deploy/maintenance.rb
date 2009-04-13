# Override deploy:web:disable to display custom message when site is down for maintenance. From Advanced Rails Recipes #69.
namespace :deploy do
  namespace :web do
    desc 'Display custom maintenance page for all requests.'
    task :disable, :roles => :web do
      require 'erb'
      on_rollback { run "rm #{shared_path}/system/maintenance.html" }
      reason = ENV['REASON']
      deadline = ENV['UNTIL']
      template = File.read("app/views/admin/maintenance.html.erb")
      page = ERB.new(template).result(binding)
      put page, "#{shared_path}/system/maintenance.html", :mode => 0644
    end
  end
end
