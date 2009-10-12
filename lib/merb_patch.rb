class Merb::Orms::DataMapper::Associations < Merb::BootLoader
   def self.run
     DataMapper::Model.descendants.each do |model|
       include DataMapper::Resource
       touch_child_keys(model)
     end
   end
   
   def self.touch_child_keys(model)
     model.relationships.each_value { |relationship| relationship.child_key }
   end
end
