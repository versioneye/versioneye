class Settings::CreditcardController < ApplicationController

  before_filter :authenticate

  def index
    plan = cookies.signed[:plan_selected]
    if plan
      @plan_name_id = plan
    end
    @billing_address = current_user.fetch_or_create_billing_address
  end

  def update
    plan_name_id = params[:plan]
    stripe_token = params[:stripeToken]
    if stripe_token.nil? || stripe_token.empty?
      flash[:error] = 'Sorry. But something went wrong. Please try again later.'
      redirect_to settings_plans_path
      return
    end
    user = current_user
    customer = StripeService.create_or_update_customer user, stripe_token, plan_name_id
    if customer
      user.stripe_token = stripe_token
      user.stripe_customer_id = customer.id
      user.plan = Plan.by_name_id plan_name_id
      user.save
      user.billing_address.update_from_params( params )
      flash[:success] = 'Many Thanks. We just updated your plan.'
    else
      flash[:error] = 'Something went wrong. Please contact the VersionEye Team.'
    end
    redirect_to settings_plans_path
  end

end
