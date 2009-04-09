require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a authority exists" do
  Authority.all.destroy!
  request(resource(:authorities), :method => "POST", 
    :params => { :authority => { :id => nil }})
end

describe "resource(:authorities)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:authorities))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of authorities" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a authority exists" do
    before(:each) do
      @response = request(resource(:authorities))
    end
    
    it "has a list of authorities" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Authority.all.destroy!
      @response = request(resource(:authorities), :method => "POST", 
        :params => { :authority => { :id => nil }})
    end
    
    it "redirects to resource(:authorities)" do
      @response.should redirect_to(resource(Authority.first), :message => {:notice => "authority was successfully created"})
    end
    
  end
end

describe "resource(@authority)" do 
  describe "a successful DELETE", :given => "a authority exists" do
     before(:each) do
       @response = request(resource(Authority.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:authorities))
     end

   end
end

describe "resource(:authorities, :new)" do
  before(:each) do
    @response = request(resource(:authorities, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@authority, :edit)", :given => "a authority exists" do
  before(:each) do
    @response = request(resource(Authority.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@authority)", :given => "a authority exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Authority.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @authority = Authority.first
      @response = request(resource(@authority), :method => "PUT", 
        :params => { :authority => {:id => @authority.id} })
    end
  
    it "redirect to the authority show action" do
      @response.should redirect_to(resource(@authority))
    end
  end
  
end

