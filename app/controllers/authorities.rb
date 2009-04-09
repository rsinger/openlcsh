class Authorities < Application
   provides :rdf, :yaml, :json
  require 'platform_client'
  def index
    @authorities = Authority.all
    display @authorities
  end

  def show(id)
    #@authority = Authority.get(id)
    #raise NotFound unless @authority
    @store = PlatformClient.create
    response = @store.describe_by_id("#{id}#concept")
    raise NotFound if response.status == 404
    @authority = Authority.new_from_json_response(response.body.content)
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

end # Authorities
