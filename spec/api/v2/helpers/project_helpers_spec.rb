require 'spec_helper'

describe ProjectHelpers do
  let(:helper) { V2::ProjectsApiV2.new }
  let(:product1) {create(:product, name: "spec_product2", prod_key: "spec_product2")}
  let(:product2) {create(:product, name: "spec_product3", prod_key: "spec_product3")}

  let(:project) {create(:project_with_deps, deps_count: 2)}
  let(:licence2) {create(:license, name: "MIT", prod_key: "spec_product3")}

  describe "add_dependency_licences" do
    before :each do
      helper.extend(ProjectHelpers)
      product1.save
      product2.save
      licence2.save
    end

    it "returns nil object when project is nil" do
      helper.add_dependency_licences(nil).should be_nil
    end

    it "returns correct licence, when product has one" do
      project.dependencies.first.save
      project_after = helper.add_dependency_licences(project)

      project_after.should_not be_nil

      dep1 = project_after.dependencies[0]
      dep1.product.should_not be_nil
      dep1.product.license.should_not be_nil
      dep1.product.license.should eql("unknown")

      dep2 = project_after.dependencies[1]
      dep2.product.should_not be_nil

      p License.all.to_a
      p dep2.product
      p dep2.product.licenses.to_a
      p dep2.product.license

      dep2.product.license.should_not be_nil
      dep2.product.license.should eql("MIT")
    end
  end
end
