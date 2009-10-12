

class PlatformClient
  @@client = nil
  private_class_method :new
  
  def self.create(config=nil)
    unless @@client
      @@client = new
      @@client.set_config(config) if config
    end    
    @@client
  end
  
  def set_config(config)
    @store = Pho::Store.new(config["store"],config["username"],config["password"])
    @resource_base_uri = config["resource_base_uri"]
  end
  
  def describe_by_id(id, content_type = nil)
    id = "#{@resource_base_uri}#{id}"
    self.describe(id, content_type)
  end
  
  def describe(uri, content_type = nil)
    unless content_type == 'application/rdf+xml'
      content_type = 'application/json'
    end
    response = @store.describe(uri, content_type)
    return nil if response.status == 404
    collection = RDFObject::Collection.new
    collection.parse(response.body.content)

    collection[uri].extend(Subject)

    return [collection[uri], collection]
  end  
  
  # This is a workaround to a bug in Pho:
  # http://rubyforge.org/tracker/index.php?func=detail&aid=25356&group_id=7855&atid=30426
  def search(query, params={})
    u = @store.build_uri('/items')
    search_params = @store.get_search_params(u, query, params)
    response = @store.client.get(u, search_params)
    uri = URI.parse(u)
    q = []
    search_params.each_pair do | key, value |
      q << "#{key}=#{CGI.escape(value.to_s)}"
    end
    uri.query = q.join("&")
    collection = RDFObject::Collection.new
    collection.parse(response.body.content)
    return [collection[uri.to_s], collection]
  end
  
  def augment(data)
    u = @store.build_uri("/services/augment")
    puts "Sending to augment service:  " + Time.now.to_s
    response = @store.client.post(u, data,{'content-type'=>'application/rss+xml'})
    puts "Return from augment service:  " + Time.now.to_s
    collection = RDFObject::Parser.parse(response.body.content)
    puts "RDFObjects parsed:  " + Time.now.to_s
    collection.uris.each do | resource |
      resource.extend(Subject)
    end
    return response
  end
  
  def construct_related_preflabels(uri, collection=RDFObject::Collection.new)
    query = "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    CONSTRUCT {?obj skos:prefLabel ?pref}
    WHERE  {
       { <#{uri}> skos:narrower ?obj } UNION
       { <#{uri}> skos:broader ?obj } UNION
       { <#{uri}> skos:related ?obj }
       { ?obj skos:prefLabel ?pref } .
    }"
    response = @store.sparql_construct(query, "application/json")
    collection.parse(response.body.content)
    collection
  end
  
end

    