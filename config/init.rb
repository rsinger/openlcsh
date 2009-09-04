# Go to http://wiki.merbivore.com/pages/init-rb
 
require 'config/dependencies.rb'
 
use_orm :datamapper
use_test :rspec
use_template_engine :erb
 
Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = '8534a3c37d9073d97946cd3891d0139461b0eb0f'  # required for cookie session store
  c[:session_id_key] = '_lcsh_session_id' # cookie session id key, defaults to "_session_id"
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  require 'platform_config'
  PlatformConfig.load  
  PlatformClient.create(Merb::Config[:platform])
end

Merb.add_mime_type(:json, :to_json, %w[application/json])
Merb.add_mime_type(:rdf, :to_rdfxml, %w[application/rdf+xml])
Merb.add_mime_type(:nt, :to_ntriples, %w[text/plain])
Merb.add_mime_type(:rss, :to_rss, %w[application/rss+xml])
Merb.add_mime_type(:atom, :to_atom, %w[application/atom+xml])