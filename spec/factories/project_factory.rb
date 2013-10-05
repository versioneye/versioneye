
FactoryGirl.define do
  factory :project do
    name "spec_project_1"
    project_type "RubyGem"
    language "Ruby"

    factory :project_with_deps do
      ignore do
        deps_count 0
      end

      after(:build) do |project, evaluator|
        prod_name = FactoryGirl.generate(:product_name)
        deps =  FactoryGirl.create_list(
          :projectdependency,
          evaluator.deps_count,
          language: project[:language]
        )
        project.projectdependencies = deps
        project.make_project_key!
      end
    end
  end
end


