require 'spec_helper'

describe ProductsHelper do
  
  before(:each) do
    @products_controller = ProductsController.new
    @products_controller.extend(ProductsHelper)
  end
  
    describe "do_parse_search_input" do 
    
    it "returns the given search input" do 
      query = "junit"
      query = @products_controller.do_parse_search_input( query )
      query.should eql("junit")
    end

    it "returns the given search input binded without -" do 
      query = "spring core"
      query = @products_controller.do_parse_search_input( query )
      query.should eql("spring core")
    end

    it "returns the given search input. stripped." do 
      query = " spring org "
      query = @products_controller.do_parse_search_input( query )
      query.should eql('spring org')
    end

    it "returns the default string json" do 
      query = nil
      query = @products_controller.do_parse_search_input( query )
      query.should eql('json')
    end
    
  end
    
end