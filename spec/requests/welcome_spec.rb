require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/welcome" do
  before(:each) do
    @response = request("/welcome")
  end
end