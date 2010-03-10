module Subject
  def to_rdfxml
    self.to_xml
  end
  
  def find_similar_resources
    similar={"dbpedia.org"=>find_dbpedia_resources}
    if is_geographic?
      similar["geonames"] = find_geonames_resources
    end
    similar["Other sources"] = find_similar_from_similar
    similar
  end
  
  def find_dbpedia_resources
    term = self.pref_label.gsub(/\s/,"_").capitalize
    resources = RDFObject::Collection.new
    concepts = RDFObject::Collection.new
    resource_uri = "http://dbpedia.org/resource/"
    concept_uri = "http://dbpedia.org/resource/Category:"

    dbpedia_lookup(resource_uri+CGI.escape(term), resources)
    dbpedia_lookup(concept_uri+CGI.escape(term), concepts )
    self.alt_labels.each do | alt |
      next unless alt
      alt_term = alt.gsub(/\s/,"_").capitalize
      dbpedia_lookup(resource_uri+CGI.escape(alt_term), resources)
      dbpedia_lookup(concept_uri+CGI.escape(alt_term), concepts )            
    end
    
    {:resources=>resources, :concepts=>concepts}
  end

  def dbpedia_lookup(uri, collection)
    return if already_asserted?(uri)
    begin
      resource = collection.find_or_create(uri)

      resource.describe if resource.empty_graph?
      if resource["http://dbpedia.org/property/redirect"] && !already_asserted?(resource["http://dbpedia.org/property/redirect"])
        collection.delete(resource.uri)     
        puts resource["http://dbpedia.org/property/redirect"].uri
        resource = collection.find_or_create(resource["http://dbpedia.org/property/redirect"].uri)
        resource.describe if resource.empty_graph?
      end
    rescue NoMethodError
      collection.delete(uri)
    end    
  end
  
  def pref_label
    return self.skos["prefLabel"]
  end
  
  def alt_labels
    alts = []
    [*self.skos['altLabel']].each do | alt |
      alts << alt
    end
    alts
  end
  
  def already_asserted?(uri)
    self.assertions.each do |predicate, objects|
      [*objects].each do | object |
        return true if object.respond_to?(:uri) and object.uri == uri
      end
    end
    false
  end
  
  def lccn
    self.uri.split("/").last.sub(/#.*$/, "")
  end
  
  def find_geonames_resources
    crit = Geonames::ToponymSearchCriteria.new
    crit.q = self.pref_label
    resources = RDFObject::Collection.new
    results = Geonames::WebService.search(crit)
    results.toponyms.each do | geoname |
      resources.find_or_create("http://sws.geonames.org/#{geoname.geoname_id}/")
    end
    self.alt_labels.each do | alt |
      next unless alt
      crit.q = alt
      results = Geonames::WebService.search(crit)
      results.toponyms.each do | geoname |
        resources.find_or_create("http://sws.geonames.org/#{geoname.geoname_id}/")
      end
    end
    {:resources=>resources}      
  end
  
  def find_similar_from_similar
    resources = RDFObject::Collection.new
    [*self.umbel["linksEntity"]].each do | rwo |
      next unless rwo
      puts rwo.inspect
      rwo = rwo.resource
      rwo.describe
      [*rwo.owl['sameAs']].each do | same |
        next unless same
        resources.find_or_create(same.uri)
      end
    end
  end
  
  def is_geographic?
    [*self.skos['inScheme']].each do | scheme |
      return true if scheme.uri == "http://lcsubjects.org/schemes/geographicNames" or scheme.uri == "http://lcsubjects.org/schemes/corporateNames"
    end
    return false
  end
end
