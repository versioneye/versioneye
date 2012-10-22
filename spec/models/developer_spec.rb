require 'spec_helper'

describe Developer do

  before(:each) do
    @developer = Developer.new({:prod_key => "junit/junit", :version => "1.0", :name => "Hans Banz", :email => "hans@banz.de"})
    @developer.save
  end
  
  after(:each) do 
    @developer.remove
  end
  
  describe "find_by" do 
    
    it "finds by the right one" do 
      developer = Developer.find_by "junit/junit", "1.0", "hans@banz.de"
      developer.should_not be_nil
    end

    it "dosnt finds by 1" do 
      developer = Developer.find_by "junit/junit", "1.1", "hans@banz.de"
      developer.should be_empty
    end

    it "dosnt finds by 2" do 
      developer = Developer.find_by "junit/junito", "1.0", "hans@banz.com"
      developer.should be_empty
    end

  end
  
end