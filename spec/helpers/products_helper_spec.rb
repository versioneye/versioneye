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
      expect(query).to eql("junit")
    end

    it "returns the given search input binded without -" do
      query = "spring core"
      query = @products_controller.do_parse_search_input( query )
      expect(query).to eql("spring core")
    end

    it "returns the given search input. stripped." do
      query = " spring org "
      query = @products_controller.do_parse_search_input( query )
      expect(query).to eql('spring org')
    end

    it "returns the default string json" do
      query = nil
      query = @products_controller.do_parse_search_input( query )
      expect(query).to eql('json')
    end

  end

  describe "display_follow" do

    it "displays block" do
      product = ProductFactory.create_new
      user = UserFactory.create_new
      expect(@products_controller.display_follow(product, user)).to eql("block")
    end

    it "displays none" do
      product = ProductFactory.create_new
      user = UserFactory.create_new
      user.products.push product
      expect(@products_controller.display_follow(product, user)).to eql("none")
    end

  end

  describe "display_unfollow" do

    it "displays block" do
      product = ProductFactory.create_new
      user = UserFactory.create_new
      user.products.push product
      expect(@products_controller.display_unfollow(product, user)).to eql("block")
    end

    it "displays none" do
      product = ProductFactory.create_new
      user = UserFactory.create_new
      expect(@products_controller.display_unfollow(product, user)).to eql("none")
    end

  end

end
