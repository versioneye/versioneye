FactoryGirl.define do

  sequence :product_name do |n|
    "spec_product#{n}"
  end

  sequence :product_version do |n|
    (n / 2.0).to_s
  end

  factory :product do
    name { generate(:product_name) }
    prod_key { generate(:product_name) }
    language "Ruby"
    version "0.1"

    factory :product_with_deps do
      ignore do
        deps_count 0
      end

      after(:create) do |product, evaluator|
        prod_name = FactoryGirl.generate(:product_name)
        FactoryGirl.create_list(:dependency, evaluator.deps_count,
                                name: prod_name,
                                prod_key: product._id.to_s,
                                prod_version: product.version,
                                language: "Ruby")
      end
    end

    factory :product_with_versions do
      ignore do
        versions_count 6
      end

      after(:create) do |product, evaluator|
        FactoryGirl.create_list(
          :dependency, evaluator.versions_count,
          version: FactoryGirl.generate(:product_version)
        )
      end
    end
  end
end
