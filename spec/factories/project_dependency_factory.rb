
FactoryGirl.define do
  factory :projectdependency do
    prod_key "spec_product1"
    language "Ruby"
    name ""
    version_current "0.1"
    version_requested "0.1"
    comperator "="
    outdated false
  end
end

