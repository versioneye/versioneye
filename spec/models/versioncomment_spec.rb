require 'spec_helper'

describe Versioncomment do

  before(:each) do
    @product          = Product.new
    @product.name     = "name"
    @product.prod_key = "gasgagasgj8623_junit/junit"
    @product.language = Product::A_LANGUAGE_JAVA
    @product.save

    @user               = User.new
    @user.fullname      = "Hans Tanz"
    @user.username      = "hanstanz"
    @user.email         = "hans@tanz.de"
    @user.password      = "password"
    @user.salt          = "salt"
    @user.terms         = true
    @user.datenerhebung = true
    @user.save

    @vc             = Versioncomment.new
    @vc.user_id     = @user.id
    @vc.product_key = @product.prod_key
    @vc.language    = @product.language
  end

  describe "save" do

    it "does not save. Because mandatory fields are empty" do
      @vc.save.should be_false
    end

    it "does save. Because mandatory fields are not empty" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.version = "1.0"
      @vc.save.should be_true
    end

  end

  describe "find_by_id" do

    it "returns nil" do
      vc = Versioncomment.find_by_id(888888888888)
      vc.should be_nil
    end

    it "returns the versioncomment" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.version = "1.0"
      @vc.save
      vc = Versioncomment.find_by_id(@vc.id)
      vc.should_not be_nil
    end

  end

  describe "find_by_user_id" do

    it "returns nil" do
      vc = Versioncomment.find_by_user_id(888888888888)
      vc.should be_empty
    end

    it "returns the versioncomment" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.version = "1.0"
      @vc.save
      vc = Versioncomment.find_by_user_id(@user.id)
      vc.should_not be_empty
      vc.size.should eql(1)
      vc[0].id.should eql(@vc.id)
    end

  end

  describe "find_by_prod_key_and_version" do

    it "returns an empty array" do
      vc = Versioncomment.find_by_prod_key_and_version("rub", "asfgasg", "a")
      vc.should be_empty
    end

    it "returns the versioncomments" do
      @vc.comment = "Jo. Voll geil eh!"
      @vc.version = "1.0"
      @vc.save
      vcs = Versioncomment.find_by_prod_key_and_version( @product.language, @product.prod_key, "1.0" )
      vcs.should_not be_empty
      vcs.size.should eql(1)
      vcs[0].id.should eql(@vc.id)
    end

  end


  describe "user" do

    it "returns the user" do
      user = @vc.user
      user.should_not be_nil
      user.id.should eql(@user.id)
    end

  end

end
