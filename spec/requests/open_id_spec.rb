require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/openid" do
  before(:each) do
    @response = request("/openid")
  end
end