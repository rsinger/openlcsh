module Subject
  require 'platform_client'

  def to_json
    json = {self.uri=>{}}
    Curie.get_mappings.each_pair do |key, value|
      if self.respond_to?(key.to_sym)
        self.send(key.to_sym).each_pair do | predicate, objects |
          pred = Curie.parse "[#{key}:#{predicate}]"
          json[self.uri][pred] = []          
          [*objects].each do | object |
            obj = {}
            if object.is_a?(RDFObject::ResourceReference)
              obj["value"] = "#{object.uri}"
              obj["type"] = "uri"
            else
              obj["value"] = object
              obj["type"] = "literal"
              if object.language
                obj["lang"] = "#{object.language}"
              end
              if object.data_type
                obj["datatype"] =  "#{object.data_type}"
              end            
            end
            json[self.uri][pred] << obj  
          end
        end
      end
    end
    json.to_json
  end
  
  def to_ntriples
    ntriples = ""
    Curie.get_mappings.each_pair do |key, value|
      if self.respond_to?(key.to_sym)
        self.send(key.to_sym).each_pair do | predicate, objects |
          [*objects].each do | object |
            ntriples << "<#{self.uri}> <#{Curie.parse "[#{key}:#{predicate}]"}> "
            if object.is_a?(RDFObject::ResourceReference)
              ntriples << " <#{object.uri}> "
            else
              ntriples << "#{object.to_json}"
              if object.language
                ntriples << "@#{object.language}"
              end
              if object.data_type
                ntriples << "^^<#{object.data_type}>"
              end              
            end
            ntriples << " . \n"          
          end
        end
      end
    end
    ntriples
  end
  
  def to_rdfxml
    rdf = "<rdf:RDF"
    Curie.get_mappings.each_pair do |key, value|
      next unless self.respond_to?(key.to_sym)
      rdf << " xmlns:#{key}=\"#{value}\""
    end
    unless rdf.match("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
      rdf << " xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\""
    end
    rdf <<"><rdf:Description rdf:about=\"#{self.uri}\">"
    Curie.get_mappings.each_pair do |key, value|
      if self.respond_to?(key.to_sym)
        self.send(key.to_sym).each_pair do | predicate, objects |
          [*objects].each do | object |
            rdf << "<#{key}:#{predicate}"
            if object.is_a?(RDFObject::ResourceReference)
              rdf << " rdf:resource=\"#{object.uri}\" />"
            else
              if object.language
                rdf << " xml:lang=\"#{object.language}\""
              end
              if object.data_type
                rdf << " rdf:datatype=\"#{object.data_type}\""
              end
              rdf << ">#{CGI.escapeHTML(object)}</#{key}:#{predicate}>"
            end
          end
        end
      end
    end
    rdf << "</rdf:Description></rdf:RDF>"
    rdf
  end
  
  def to_rss
    rss = "<rdf:RDF xmlns=\"http://purl.org/rss/1.0/\" "
    Curie.get_mappings.each_pair do |key, value|
      next unless self.respond_to?(key.to_sym)
      rss << "xmlns:#{key}=\"#{value}\" "
    end
    rss << "xmlns:relevance=\"http://a9.com/-/opensearch/extensions/relevance/1.0/\" "
    rss << "xmlns:os=\"http://a9.com/-/spec/opensearch/1.1/\">" 
    rss << "<channel rdf:about=\"#{self.uri}\">"
    rss << "<link>#{self.uri}</link>"
    rss << "<title>#{CGI.escapeHTML(self.skos['prefLabel'])}</title>"
    rss << "<description>#{CGI.escapeHTML(self.skos['prefLabel'])} as found at:  #{self.uri}</description>"
    rss << "<items>"
    rss << "<rdf:Seq><rdf:li rdf:resource=\"#{self.uri}\"/></rdf:Seq>"
    rss << "</items>"
    rss << "</channel>"
    rss << "<item rdf:about=\"#{self.uri}\">"
    rss << "<title>#{CGI.escapeHTML(self.skos['prefLabel'])}</title>"
    rss << "<link>#{self.uri}</link>"
    Curie.get_mappings.each_pair do |key, value|
      if self.respond_to?(key.to_sym)
        self.send(key.to_sym).each_pair do | predicate, objects |
          [*objects].each do | object |
            rss << "<#{key}:#{predicate}"
            if object.is_a?(RDFObject::ResourceReference)
              rss << " rdf:resource=\"#{object.uri}\" />"
            else
              rss << ">#{CGI.escapeHTML(object)}</#{key}:#{predicate}>"
            end
          end
        end
      end
    end     
    rss << "</item>"
    rss << "</rdf:RDF>"
    rss
  end
  
  def self.new_from_rss_response(content)
    results = SearchResult.new
    namespaces = {:os=>{'os'=>'http://a9.com/-/spec/opensearch/1.1/'},:rdf=>{'rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#'},
      :skos=>{'skos'=>'http://www.w3.org/2004/02/skos/core#'}, :rss=>{'rss'=>'http://purl.org/rss/1.0/'}}
    doc = Nokogiri::XML(content)
    if total = doc.xpath('//rss:channel/os:totalResults', namespaces[:rss].merge(namespaces[:os]))
      results.total_results = total.first.content.to_i if total.first
    end
    if items_per_page = doc.xpath('//rss:channel/os:itemsPerPage', namespaces[:rss].merge(namespaces[:os]))
      results.items_per_page = items_per_page.first.content.to_i
    end  
    if offset = doc.xpath('//rss:channel/os:startIndex', namespaces[:rss].merge(namespaces[:os]))
      results.offset = offset.first.content.to_i
    end    
    doc.xpath('//rss:item', namespaces[:rss]).each do | item |
      results << self.new_subject_from_rss_item(item)
    end
    results
  end
  
  def self.new_subject_from_rss_item(item)
    namespaces = {:os=>{'os'=>'http://a9.com/-/spec/opensearch/1.1/'},:rdf=>{'rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#'},
      :skos=>{'skos'=>'http://www.w3.org/2004/02/skos/core#'}, :rss=>{'rss'=>'http://purl.org/rss/1.0/'}}    
    subj = self.new
    subj.uri = item['about']
    if pl = item.xpath('./skos:prefLabel', namespaces[:skos])
      subj.pref_label = pl.first.content if pl.first
    end
    item.xpath('./skos:altLabel', namespaces[:skos]).each do | al |
      subj.alt_labels ||=[]
      subj.alt_labels << al.content
    end
    subj    
  end
  
  def self.new_from_augment_service(content)
    related = []
    namespaces = {:os=>{'os'=>'http://a9.com/-/spec/opensearch/1.1/'},:rdf=>{'rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#'},
      :skos=>{'skos'=>'http://www.w3.org/2004/02/skos/core#'}, :rss=>{'rss'=>'http://purl.org/rss/1.0/'}}
    doc = Nokogiri::XML(content) 
    doc.xpath('//rss:item', namespaces[:rss]).each do | item |
      item.xpath('//skos:Concept', namespaces[:skos]).each do | concept |
        related << self.new_subject_from_rss_item(concept)
      end
    end       
    return related
  end
end
