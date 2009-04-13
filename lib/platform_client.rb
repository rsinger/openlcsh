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
end
    