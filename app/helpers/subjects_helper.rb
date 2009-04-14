module Merb
  module SubjectsHelper
    def grab_resource(uri)
      return Subject.new_from_json_response(@store.describe(uri).body.content)
    end
    
    def related_resource(uri)
      @related ||={:lookup=>true}
      if @related[:lookup]
        resp = @store.augment(@authority.to_rss)
        relations = Subject.new_from_augment_service(resp.body.content)
        if relations
          relations.each do | r |
            @related[r.uri] = r
          end
        end
        @related.delete(:lookup)
      end
      @related[uri]
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
          start = (search_results.offset-search_results.items_per_page)/search_results.items_per_page
          if (search_results.offset/search_results.items_per_page) == total_pages
            endpoint = total_pages
          else
            endpoint = (search_results.offset+search_results.items_per_page)/search_results.items_per_page
          end
          ranges << (start..endpoint)
        end
        if !endpoint || endpoint < total_pages
          bottom = (total_pages-4)
          rng = (bottom..total_pages)
          while rng.include?(endpoint)
            bottom += 1
            rng = (bottom..total_pages)
          end
          ranges << rng
        end
      else
        ranges << (0..total_pages)
      end
      ranges
    end   
    
    def prev_page_offset(results) 
      offset = 0
      if (results.offset - results.items_per_page) > 0
        offset = (results.offset - results.items_per_page)
      end
      offset
    end
  end
end # Merb