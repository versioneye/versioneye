require 'spec_helper'

describe ErrorMessage do
  
  describe "crawle" do 
    
    it "delivers the right crawle" do 
      crawle = Crawle.new  
      crawle.crawler_name = "test_crawler"
      crawle.save

      error = ErrorMessage.new({:subject => "subject", :errormessage => "this is an error", :source => "my_source", :crawle_id => crawle.id })
      cr = error.crawle
      cr.should_not be_nil
      cr.crawler_name.should eql("test_crawler")
      cr.error_messages.size.should eq(1)
    end

  end
  
end