class Settings::BillingController < ApplicationController

  before_filter :authenticate

  def index
    @billing_address = current_user.fetch_or_create_billing_address
  end

  def update
    @billing_address = current_user.fetch_or_create_billing_address
    if @billing_address.update_from_params params
      flash.now[:success] = "Your billing address was saved successfully."
    else
      flash.now[:error] = "An error occured. Please try again."
    end
    render "index"
  end

end
