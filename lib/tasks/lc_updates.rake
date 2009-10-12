require 'open-uri'
namespace :lcsh do
  desc "Sync LCSubjects.org with the Atom feed from id.loc.gov"
  task :update => :merb_env do
    last_update = Update.first(:order=>[:updated.desc])
    feed = open('http://id.loc.gov/authorities/feed/')
    puts feed.read
  end
end
