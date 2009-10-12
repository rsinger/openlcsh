class Update
  include DataMapper::Resource
  
  property :id, Serial
  property :lc_uri, String, :length => 255, :index => true
  property :action, String, :index => true
  property :updated, DateTime, :index => true
  property :created_at, DateTime, :index => true


end
