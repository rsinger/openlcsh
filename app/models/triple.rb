class Triple
  include DataMapper::Resource
  belongs_to :user
  property :id, Serial
  property :subject, String, :nullable => false, :index => true
  property :predicate, String, :nullable => false, :index => true
  property :object_resource, String, :index => true
  property :object_literal, Text
  property :data_type, String
  property :language, String
  property :user_id, Integer, :nullable => false, :index => true
  property :published, Boolean, :nullable => false, :default => false, :index => true
  property :approved_by, Integer, :index => true
  property :created_at, DateTime  

end
