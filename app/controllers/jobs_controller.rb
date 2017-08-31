class JobsController < ApplicationController


  def index
    @billing_address = BillingAddress.new
  end


  def create
		billing_address = BillingAddress.new
    if billing_address.update_from_params( params ) == false
      flash[:error] = 'Please complete the billing information.'
      redirect_back
      return
    end

    stripe_token = params[:stripeToken]
    if stripe_token.to_s.empty?
      flash[:error] = 'Stripe token is missing. Please contact the VersionEye Team.'
      redirect_back
      return
    end

    Stripe::Charge.create(
      :amount => 47600,
      :currency => "eur",
      :source => stripe_token,
      :description => "Charge for 1 job posting for #{billing_address.email}, #{billing_address.type}, #{billing_address.name}, #{billing_address.street}, #{billing_address.zip}, #{billing_address.city}, #{billing_address.country}, #{billing_address.company}, #{billing_address.taxid}"
    )
  end


end
