set :application, "lcsh"
#set :repository,  "set your repository location here"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "anvil.lisforge.net"
set :deploy_to, "/home/rsinger/rails-sites/#{application}"
role :web, "lcsubjects.org"
set :user, 'rsinger'
role :db,  "anvil.lisforge.net", :primary => true