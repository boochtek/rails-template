# TODO: Should create DBs if required. (Depend on db:create.)
# TODO: Should work on test and development databases?
namespace :db do
  desc "Sync database to DataMapper models."
  task :auto_upgrade do
    DataMapper.auto_upgrade
  end
end
