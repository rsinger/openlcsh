require 'lcsubjects'
FileUtils.mkdir_p 'log' unless File.exists?('log')
log = File.new("log/sinatra.log", "a")
set :environment, :production
$stdout.reopen(log)
$stderr.reopen(log)
run Sinatra::Application
