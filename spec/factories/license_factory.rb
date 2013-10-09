FactoryGirl.define do
  sequence(:license_name) {|n| ["unknown", "MIT", "Eclipse"][(n % 3)]}

  factory :license do
    name "unknown"
    language "Ruby"
    prod_key "spec_1"
    version "0.0"
  end
end