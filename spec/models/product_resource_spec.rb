require 'spec_helper'

describe ProductResource do
  
  describe "validation" do
    it 'cant save when url is missing' do
      resource = ProductResource.new url: "http://versioneye.com"
      resource.save.should_not be_true
    end

    it 'cant save when resource_type is missing' do
      resource = ProductResource.new resource_type: "user"
      resource.save.should_not be_true
    end
  end

  describe 'submitted_url' do
    it "saves submitted_url correctly" do
      new_url = SubmittedUrl.new url: "http://versioneye.com",
                                 message: "#1-2-3",
                                 user_email: "test_url@versioneye.com"
      new_url.save
      resource = ProductResource.new url: new_url.url,
                                     resource_type: "user",
                                     submitted_url: new_url

      resource.submitted_url[:url].should eql("http://versioneye.com")
      resource.submitted_url.message.should eql("#1-2-3")
      resource.delete
      new_url.delete
    end
  end

  describe 'find_by_id' do
    it "returns nil, if id is nil" do
      ProductResource.find_by_id(nil).should be_nil
    end

    it "returns nil, if object with given id dont exists" do
      ProductResource.find_by_id("bullshithbongo").should be_nil
    end

    it "returns object, if object wih given id exists" do
      new_resource = ProductResource.new url: "abc.de", resource_type: "123"
      new_resource.save
      search_result = ProductResource.find_by_id(new_resource.id)
      search_result.url.should eql(new_resource.url)
      new_resource.delete
    end
  end 
end
