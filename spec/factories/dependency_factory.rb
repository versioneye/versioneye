
FactoryGirl.define do

  factory :dependency do
    name "spec_prod2"
    version "0.1.1"
    dep_prod_key "spec_dep1_key"
    prod_key ""
    prod_version "0.1"
    known true
  end

end

