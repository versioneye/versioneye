require 'spec_helper'

describe Project do

  before(:each) do
    user        = UserFactory.create_new
    @product    = ProductFactory.create_new(1, :maven, true, "2.0.0")
    @project    = ProjectFactory.create_new( user )
  end

  describe "outdated?" do

    it "is not outdated" do
      dep_1 = ProjectdependencyFactory.create_new( @project, @product )
      dep_1.version_current   = @product.version
      dep_1.version_requested = @product.version
      dep_1.save
      outdated = @project.outdated?
      outdated.should be_false
    end

    it "is outdated" do
      dep_1 = ProjectdependencyFactory.create_new( @project, @product )
      dep_1.version_current   = "2.0.0"
      dep_1.version_requested = "1.0.0"
      dep_1.save
      outdated = @project.outdated?
      outdated.should be_true
    end

  end

end
