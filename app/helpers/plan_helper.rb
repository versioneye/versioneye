module PlanHelper

  def has_current_plan?( user )
    return false if user.nil?
    return false if user.plan.nil?

    Plan.current_plans.each do |plan|
      return true if plan.name_id.eql?( user.plan.name_id )
    end

    return false;
  end

end
