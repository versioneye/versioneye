
FactoryGirl.define do
  sequence :product_name do |n|
    "spec_product#{n}"
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
  end
end

