module Merb
  module SubjectsHelper
    def grab_resource(uri)
      return Subject.new_from_json_response(@store.describe(uri).body.content)
    end
    
    def set_mime_type(format)
      if format == :rdf
        return 'application/rdf+xml'
      end
      return 'application/json'      
    end

  end
end # Merb