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
    
    def date_display(date)
      unless date.is_a?(DateTime)
        date = DateTime.parse(date)
      end
      date.strftime("%A, %B %d, %Y - %I:%m:%S %p")
    end
    def generate_facet_link(uri)
      u = URI.parse(uri)
      q = CGI.parse(u.query)
      url = "/search?q=#{CGI.escape(q["query"].first)}"
      if params[:offset]
        url << "&offset=#{params[:offset]}"
      end
      url
    end
    
    def scheme_labels(scheme)
      label = case scheme.uri
      when "http://lcsubjects.org/schemes/conceptScheme" then "LCSubjects.org"
      when "http://lcsubjects.org/schemes/authorizedHeadings" then "LC Authorized Headings"
      when "http://lcsubjects.org/schemes/topicalTerms" then "Topical Terms"
      when "http://lcsubjects.org/schemes/geographicNames" then "Geographic Names"
      when "http://lcsubjects.org/schemes/corporateNames" then "Corporate Names"
      when "http://lcsubjects.org/schemes/personalNames" then "Personal Names"
      when "http://lcsubjects.org/schemes/generalSubdivision" then "General Subdivisions"
      when "http://lcsubjects.org/schemes/uniformTitles" then "Uniform Titles"
      when "http://lcsubjects.org/schemes/formSubdivision" then "Form Subdivisions"
      when "http://lcsubjects.org/schemes/chronologicalSubdivision" then "Chronological Subdivisions"
      when "http://lcsubjects.org/schemes/genreFormTerms" then "Genre/Form Terms"
      when "http://lcsubjects.org/schemes/meetings" then "Meetings"
      when "http://lcsubjects.org/schemes/geographicSubdivision" then "Geographic Subdivisions"
      end
      label
    end
  end
end # Merb