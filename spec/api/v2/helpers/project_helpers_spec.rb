require 'spec_helper'

describe ProjectHelpers do
  let(:helper) { V2::ProjectsApiV2.new }
  let(:product1) {create(:product, name: "spec_product_2", prod_key: "spec_product_2", license: "MIT")}
  let(:product2) {create(:product, name: "spec_product_3", prod_key: "spec_product_3", license: nil)}

  let(:project) {create(:project_with_deps, deps_count: 2)}

  describe "add_dependency_licences" do
    before :each do
      helper.extend(ProjectHelpers)
    end

    it "returns nil object when project is nil" do
      helper.add_dependency_licences(nil).should be_nil
    end

    it "returns correct licence, when product has one" do
      project.dependencies.first.save

      p product1
      p project.dependencies[0]
      project_after = helper.add_dependency_licences(project)
      p project_after.dependencies[0]

      project_after.should_not be_nil

      dep1 = project_after.dependencies[0]
      dep1[:license].should_not be_nil
      dep1[:license].should eql("MIT")

    end
  end
end
