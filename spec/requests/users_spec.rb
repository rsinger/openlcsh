require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/users" do
  before(:each) do
    @response = request("/users")
  end
end