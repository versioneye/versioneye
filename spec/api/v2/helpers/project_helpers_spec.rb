require 'spec_helper'

describe ProjectHelpers do

  let(:helper) { V2::ProjectsApiV2.new }
  let(:product1) {create(:product, name: "spec_product1", prod_key: "spec_product1", language: 'Ruby', prod_type: 'RubyGems')}
  let(:product2) {create(:product, name: "spec_product2", prod_key: "spec_product2", language: 'Ruby', prod_type: 'RubyGems')}
  let(:project) {create(:project_with_deps, deps_count: 2)}
  let(:licence2) {create(:license, name: "MIT", prod_key: "spec_product2")}

  describe "add_dependency_licences" do
    before :each do
      FactoryGirl.reload
      helper.extend(ProjectHelpers)
      product1.save
      product2.save
      licence2.version = product2.version
      licence2.save

      dep_1 = Projectdependency.new(:language => product1.language, :prod_key => product1.prod_key)
      dep_1.save
      dep_2 = Projectdependency.new(:language => product2.language, :prod_key => product2.prod_key)
      dep_2.save
      project.dependencies.delete_all
      project.dependencies.push dep_1
      project.dependencies.push dep_2
    end

    it "returns nil object when project is nil" do
      helper.add_dependency_licences(nil).should be_nil
    end

    it "returns correct licence, when product has one" do
      project.dependencies.first.save
      project.dependencies.last.save
      project.dependencies.count.should eq(2)
      project_after = helper.add_dependency_licences(project)

      project_after.should_not be_nil
      project_after.dependencies.size.should eq(2)

      dep1 = project_after.dependencies[0]

      dep1.should_not be_nil
      dep1.product.should_not be_nil
      dep1.product.license_info.should_not be_nil
      dep1.product.license_info.should eql("unknown")

      dep2 = project_after.dependencies[1]
      dep2.should_not be_nil
      dep2.product.should_not be_nil
      dep2.product.license_info.should_not be_nil
      dep2.product.license_info.should eql("MIT")
    end
  end
end
