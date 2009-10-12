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
      total_results = search_results["http://a9.com/-/spec/opensearch/1.1/totalResults"].to_i
      items_per_page = search_results["http://a9.com/-/spec/opensearch/1.1/itemsPerPage"].to_i
      offset = search_results["http://a9.com/-/spec/opensearch/1.1/startIndex"].to_i
      total_pages = total_results.divmod(items_per_page)[0]
      return nil if total_pages < 1
      ranges = []
      if total_pages > 10        
        if offset != (5*items_per_page)
          ranges << (0..4)
        end
        if offset == (5*items_per_page)
          ranges << (5..6)
        else
          ranges << '...'
        end
        start = nil
        endpoint = nil
        if offset > (5*items_per_page)
          start = (offset-items_per_page)/items_per_page
          if (offset/items_per_page) == total_pages
            endpoint = total_pages
          else
            endpoint = (offset+items_per_page)/items_per_page
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
      items_per_page = results["http://a9.com/-/spec/opensearch/1.1/itemsPerPage"].to_i      
      if (results["http://a9.com/-/spec/opensearch/1.1/startIndex"].to_i - items_per_page) > 0
        offset = (results["http://a9.com/-/spec/opensearch/1.1/startIndex"].to_i - items_per_page)
      end
      offset
    end
  end
end # Merb