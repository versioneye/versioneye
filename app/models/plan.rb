class Plan

  include Mongoid::Document
  include Mongoid::Timestamps

  A_PLAN_FREE            = '02_free'
  A_PLAN_PERSONAL        = '02_personal'
  A_PLAN_BUSINESS_SMALL  = '02_business_small'
  A_PLAN_BUSINESS_NORMAL = '02_business_normal'

  field :name_id         , type: String
  field :name            , type: String
  field :price           , type: String
  field :private_projects, type: Integer

  has_many :users

  def self.by_name_id name_id
    Plan.where(:name_id => name_id).shift
  end

  def self.create_default_plans
    free = Plan.new
    free.name_id = A_PLAN_FREE
    free.name = 'Free'
    free.price = '0'
    free.private_projects = 0
    free.save

  	plan = Plan.new
  	plan.name_id = A_PLAN_PERSONAL
  	plan.name = 'Personal'
  	plan.price = '3'
  	plan.private_projects = 5
  	plan.save

  	plan2 = Plan.new
  	plan2.name_id = A_PLAN_BUSINESS_SMALL
  	plan2.name = 'Business - Small'
  	plan2.price = '7'
  	plan2.private_projects = 10
  	plan2.save

  	plan3 = Plan.new
  	plan3.name_id = A_PLAN_BUSINESS_NORMAL
  	plan3.name = 'Business - Normal'
  	plan3.price = '25'
  	plan3.private_projects = 50
  	plan3.save
  end

  def self.current_plans
    Plan.where(name_id: /^02/)
  end

  def self.free_plan
    Plan.where(name_id: A_PLAN_FREE).shift
  end

  def self.personal_plan
    Plan.where(name_id: A_PLAN_PERSONAL).shift
  end

  def self.business_small_plan
    Plan.where(name_id: A_PLAN_BUSINESS_SMALL).shift
  end

  def self.business_normal_plan
    Plan.where(name_id: A_PLAN_BUSINESS_NORMAL).shift
  end

end
