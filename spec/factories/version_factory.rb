FactoryGirl.define do
  factory :product_version, class: Version do
    version "0.0.1"
    released_at 1.minutes.ago
  end
end
