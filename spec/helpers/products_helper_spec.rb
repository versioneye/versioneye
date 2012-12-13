require 'spec_helper'

describe ProductsHelper do
  
  before(:each) do
    @products_controller = ProductsController.new
    @products_controller.extend(ProductsHelper)
  end
  
  describe "do_parse_search_input" do 
    
    it "returns the given search input" do 
      query = "junit"
      hash = @products_controller.do_parse_search_input( query , nil)
      hash['query'].should eql("junit")
    end

    it "returns the given search input binded without -" do 
      query = "spring core"
      hash = @products_controller.do_parse_search_input( query, nil)
      hash['query'].should eql("spring core")
    end

    it "returns the given search input. Parsed the the group" do 
      query = "spring g:org"
      hash = @products_controller.do_parse_search_input( query, nil)
      hash['group'].should eql('org')
      hash['query'].should eql("spring")
    end

    it "returns the default string json" do 
      query = nil
      hash = @products_controller.do_parse_search_input( query , nil)
      hash['query'].should eql('json')
      hash['group'].should be_nil
    end
    
  end
    
end