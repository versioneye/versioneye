
FactoryGirl.define do
  factory :projectdependency do
    prod_key { generate(:product_name) }
    language "Ruby"
    name ""
    version_current "0.1"
    version_requested "0.1"
    comperator "="
    outdated false
    ext_link ""

    factory :projectdependency_with_licenses do
      transient do
        license_count 1
      end

      after(:create) do |dep, evaluator|
        FactoryGirl.create_list(
          :license, evaluator.license_count,
          language: dep[:language],
          prod_key: dep[:prod_key],
          version: dep[:version]
        )
      end
    end
  end
end

