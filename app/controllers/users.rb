class Users < Application
  # provides :xml, :yaml, :js
  before :ensure_authenticated
 
  def index
    @users = User.all
    display @users
  end
 
  def show(id)
    @user = User.get(id)
    raise NotFound unless @user
    display @user
  end
 
  def login
    # if the user is logged in, then redirect them to their profile
    redirect (session[:login_location]||'/'), :message => { :notice => 'You are now logged in' }
  end
 
end