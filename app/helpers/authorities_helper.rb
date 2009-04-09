module Merb
  module AuthoritiesHelper
    def grab_resource(uri)
      return Authority.new_from_json_response(@store.describe(uri).body.content)
    end

  end
end # Merb