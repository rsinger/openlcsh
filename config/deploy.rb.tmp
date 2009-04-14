set :application, "lcsh"
set :repository,  "git://github.com/rsinger/openlcsh.git"
set :local_repository, "ssh://rsinger@anvil.lisforge.net/home/rsinger/git/lcsh.git"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git
set :branch, "master"

role :app, "anvil.lisforge.net"
set :deploy_to, "/home/rsinger/rails-sites/#{application}"
#role :web, "lcsubjects.org"
set :user, 'rsinger'
set :use_sudo, true
set(:password) { Capistrano::CLI.ui.ask("Password: ") }

role :db,  "anvil.lisforge.net", :primary => true

namespace :deploy do
  task :symlink_shared do
    run "ln -s #{shared_path}/platform.yml #{current_path}/config/"
  end  
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
 
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end  
end
before "deploy:restart", "deploy:symlink_shared"
