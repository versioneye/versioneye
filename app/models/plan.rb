class Plan
  
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name_id, type: String
  field :name, type: String
  field :price, type: String
  field :private_projects, type: Integer

  def self.create_default_plans
    free = Plan.new
    free.name_id = "01_free"
    free.name = "Free"
    free.price = "0"
    free.private_projects = 0
    free.save

  	plan = Plan.new
  	plan.name_id = "01_micro"
  	plan.name = "Micro"
  	plan.price = "7"
  	plan.private_projects = 1
  	plan.save

  	plan2 = Plan.new
  	plan2.name_id = "01_small"
  	plan2.name = "Small"
  	plan2.price = "12"
  	plan2.private_projects = 2
  	plan2.save

  	plan3 = Plan.new
  	plan3.name_id = "01_medium"
  	plan3.name = "Medium"
  	plan3.price = "20"
  	plan3.private_projects = 4
  	plan3.save

  	plan4 = Plan.new
  	plan4.name_id = "01_large"
  	plan4.name = "Large"
  	plan4.price = "47"
  	plan4.private_projects = 10
  	plan4.save
  end
  
end