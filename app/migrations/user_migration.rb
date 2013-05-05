class UserMigration

  def self.migrate_plans
    free_plan = Plan.free_plan
    users = User.all 
    users.each do |user|
      if user.plan_name_id 
        plan = Plan.where(name_id: user.plan_name_id).shift
      else 
        plan = free_plan
      end
      user.plan = plan 
      user.save 
      p "#{user.fullname} => #{plan.name}"
    end
  end

end 
