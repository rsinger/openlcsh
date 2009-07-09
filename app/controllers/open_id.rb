class OpenId < Merb::Controller
  before :ensure_openid_url
  def login

  end
  
  def register
    attributes = {
      :name => session['openid.nickname'],
      :email => session['openid.email'],
      :identity_url => session['openid.url'],
      :registration_timestamp => DateTime.now(),
    }
     
    user = Merb::Authentication.user_class.first_or_create(
      attributes.only(:identity_url)
    )
    
     
    if user.update_attributes(attributes)
      session.user = user
      #redirect url(:user, session.user.id), :message => { :notice => 'Signup was successful' }
      redirect url(session[:login_location])
    else
      message[:error] = 'There was an error while creating your user account'
      redirect(url(:openid), {:location=>params[:location]})
    end
  end

  def signout
    session.user = nil
    redirect(params['location'])
  end
  
  private
 
  def ensure_openid_url
    throw :halt, redirect(url(:openid)) if session['openid.url'].nil?
  end
  

end