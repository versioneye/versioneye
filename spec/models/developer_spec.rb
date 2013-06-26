require 'spec_helper'

describe Developer do

  before(:each) do
    Developer.destroy_all
    @developer = Developer.new({:language => Product::A_LANGUAGE_JAVA, :prod_key => "junit/junit", :version => "1.0", :name => "Hans Banz", :email => "hans@banz.de"})
    @developer.save
  end

  describe "find_by" do

    it "finds by the right one" do
      developer = Developer.find_by Product::A_LANGUAGE_JAVA, "junit/junit", "1.0", "hans@banz.de"
      developer.should_not be_nil
    end

    it "dosnt finds by 1" do
      developer = Developer.find_by Product::A_LANGUAGE_JAVA, "junit/junit", "1.1", "hans@banz.de"
      developer.should be_empty
    end

    it "dosnt finds by 2" do
      developer = Developer.find_by Product::A_LANGUAGE_JAVA, "junit/junito", "1.0", "hans@banz.com"
      developer.should be_empty
    end

  end

end
