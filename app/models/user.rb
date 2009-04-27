# This is a default user class used to activate merb-auth.  Feel free to change from a User to 
# Some other class, or to remove it altogether.  If removed, merb-auth may not work by default.
#
# Don't forget that by default the salted_user mixin is used from merb-more
# You'll need to setup your db as per the salted_user mixin, and you'll need
# To use :password, and :password_confirmation when creating a user
#
# see merb/merb-auth/setup.rb to see how to disable the salted_user mixin
# 
# You will need to setup your database and create a user.
class User
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :nullable => true
  property :email, String, :nullable => true
  property :identity_url, String, :nullable => false, :unique => true, :unique_index => true
  property :approved, Boolean, :nullable => false, :default => false
  property :approved_by, Integer, :nullable => true
  property :registration_timestamp, DateTime, :nullable => true
  property :approved_timestamp, DateTime, :nullable => true
  property :blocked, Boolean, :nullable => false, :default => false
  property :flagged, Boolean, :nullable => false, :default => false
  property :block_timestamp, DateTime, :nullable => true
  property :last_login, DateTime, :nullable => true
  property :permission_level, Integer, :nullable => false, :default => 0
  
  #validates_format :email, :as => :email_address
  def password_required?; false end
end
