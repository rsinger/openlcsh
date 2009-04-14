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
    
    def paginate(search_results)
      total_pages = search_results.total_results.divmod(search_results.items_per_page)[0]
      return nil if total_pages < 1
      ranges = []
      if total_pages > 10        
        if search_results.offset != (5*search_results.items_per_page)
          ranges << (0..4)
        end
        if search_results.offset == (5*search_results.items_per_page)
          ranges << (5..6)
        else
          ranges << '...'
        end
        start = nil
        endpoint = nil
        if search_results.offset > (5*search_results.items_per_page)
          start = (search_results.offset-search_results.item_per_page)/search_results.items_per_page
          if (search_results.offset/search_results.items_per_page) == total_pages
            endpoint = total_pages
          else
            endpoint = (search_results.offset+search_results.item_per_page)/search_results.items_per_page
          end
          ranges << (start..endpoint)
        end
        if endpoint < total_pages
          bottom = (total_pages-5)
          rng = (bottom..total_pages)
          while rng.includes?(endpoint)
            bottom -= 1
            rng = (bottom..total_pages)
          end
          ranges << rng
        end
      else
        ranges << (0..total_pages)
      end
      ranges
    end    
  end
end # Merb