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
  
  def describe_by_id(id, cache=nil)
    etag = nil
    id = "#{@resource_base_uri}#{id}"
    if cache
      etag = Pho::Etags.new
      etag.add(cache.uri, cache.etag)
    end
    puts id
    @store.describe(id, 'application/json', etag)
  end
  def describe(uri, cache=nil)
    etag = nil
    if cache
      etag = Pho::Etags.new
      etag.add(cache.uri, cache.etag)
    end
    puts uri
    @store.describe(uri, 'application/json', etag)
  end  
end
    