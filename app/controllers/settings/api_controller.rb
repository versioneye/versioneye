class Settings::ApiController < ApplicationController


  before_filter :authenticate


  def index
    @user_api = current_user.api
    @api_calls = 0
    if @user_api.api_key.nil?
      @user_api.api_key = 'generate new value'
    else
      @api_calls = ApiCall.where(:api_key => @user_api.api_key).count
    end
  end


  def update
    @user_api = current_user.api
    @user_api.generate_api_key!
    if current_user.plan
      @user_api.rate_limit = current_user.plan.api_rate_limit
    end

    unless @user_api.save
      flash[:notice] << @user_api.errors.full_messages.to_sentence
    end
    redirect_to :back
  end


end
