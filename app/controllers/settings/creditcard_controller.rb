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
    user = current_user
    billing_address = user.fetch_or_create_billing_address
    if billing_address.update_from_params( params ) == false
      flash[:error] = 'Please complete the billing information.'
      redirect_to settings_creditcard_path
      return
    end

    plan_name_id = params[:plan]
    stripe_token = params[:stripeToken]
    if stripe_token.to_s.empty? || plan_name_id.to_s.empty?
      flash[:error] = 'Stripe token is missing. Please contact the VersionEye Team.'
      redirect_to settings_creditcard_path
      return
    end

    customer = StripeService.create_or_update_customer user, stripe_token, plan_name_id
    if customer.nil?
      flash[:error] = 'Stripe customer is missing. Please contact the VersionEye Team.'
      redirect_to settings_creditcard_path
      return
    end

    user.stripe_token = stripe_token
    user.stripe_customer_id = customer.id
    user.plan = Plan.by_name_id plan_name_id
    user.save

    flash[:success] = 'Many Thanks. We just updated your plan.'
    redirect_to settings_creditcard_path
  end

end
