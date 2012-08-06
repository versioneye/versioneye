require 'spec_helper'

describe ProductsHelper do
  
  before(:each) do
    @products_controller = ProductsController.new
    @products_controller.extend(ProductsHelper)
  end
  
  describe "do_parse_search_input" do 
    
    it "returns the given search input" do 
      query = "junit"
      description = nil
      hash = @products_controller.do_parse_search_input( query , description, nil)
      hash['description'].should be_nil
      hash['query'].should eql("junit")
    end

    it "returns the given search input binded with -" do 
      query = "spring core"
      description = nil
      hash = @products_controller.do_parse_search_input( query , description, nil)
      hash['description'].should be_nil
      hash['query'].should eql("spring-core")
    end

    it "returns the given search input. Parsed the description and the group" do 
      query = "spring d:core g:org"
      description = nil
      hash = @products_controller.do_parse_search_input( query , description, nil)
      hash['description'].should eql('core')
      hash['group'].should eql('org')
      hash['query'].should eql("spring")
    end

    it "returns the default string json" do 
      query = nil
      description = nil
      hash = @products_controller.do_parse_search_input( query , description, nil)
      hash['query'].should eql('json')
      hash['group'].should be_nil
      hash['description'].should be_nil
    end
    
  end
    
end