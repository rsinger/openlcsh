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
    @store.describe(uri, content_type)
  end  
  
  # This is a workaround to a bug in Pho:
  # http://rubyforge.org/tracker/index.php?func=detail&aid=25356&group_id=7855&atid=30426
  def search(query, params={})
    u = @store.build_uri('/items')
    search_params = @store.get_search_params(u, query, params)
    @store.client.get(u, search_params)
  end
  
  def augment(data)
    u = @store.build_uri("/services/augment")
    response = @store.client.post(u, data,{'content-type'=>'application/rss+xml'})
    return response
  end
  
end
    