class Subjects < Application
   provides :rdf, :json, :nt, :rss
  require 'platform_client'
  def index
    @store = PlatformClient.create
    opts = {:max=>50,'offset'=>(params['offset']||0),:sort=>'preflabel'}
    response = @store.search('*:*', opts)
    @results = Subject.new_from_rss_response(response.body.content)
    @title = 'All LCSH'
    display @results
  end

  def show(id)
    @store = PlatformClient.create
    response = @store.describe_by_id("#{id}#concept", set_mime_type(content_type))
    raise NotFound if response.status == 404
    @authority = Subject.new_from_platform(response)
    raise NotFound unless @authority
    @title = @authority.pref_label
    display @authority
  end

  def new
    only_provides :html
    @authority = Authority.new
    display @authority
  end

  def edit(id)
    only_provides :html
    @authority = Authority.get(id)
    raise NotFound unless @authority
    display @authority
  end

  def create(authority)
    @authority = Authority.new(authority)
    if @authority.save
      redirect resource(@authority), :message => {:notice => "Authority was successfully created"}
    else
      message[:error] = "Authority failed to be created"
      render :new
    end
  end

  def update(id, authority)
    @authority = Authority.get(id)
    raise NotFound unless @authority
    if @authority.update_attributes(authority)
       redirect resource(@authority)
    else
      display @authority, :edit
    end
  end

  def destroy(id)
    @authority = Authority.get(id)
    raise NotFound unless @authority
    if @authority.destroy
      redirect resource(:authorities)
    else
      raise InternalServerError
    end
  end
  
  def search
    @results = nil
    @title = 'Search LCSubjects.org'
    if params['q']
      opts = {}
      opts['max'] = params['max']||25
      opts['offset'] = params['offset']||0
      if params['sort']
        opts['sort'] = params['sort']
      end
      @store = PlatformClient.create
      response = @store.search(params['q'], opts)
      @results = Subject.new_from_platform(response)
      @title << ": #{params['q']}"
    end
    display @results   
  end

end # Authorities
