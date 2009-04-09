module Merb
  module SubjectsHelper
    def grab_resource(uri)
      return Subject.new_from_json_response(@store.describe(uri).body.content)
    end

  end
end # Merb