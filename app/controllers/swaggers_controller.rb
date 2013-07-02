class SwaggersController < ApplicationController

  force_ssl
#FIX: rails cant find API model
  def index
    @current_user = current_user
    user_api = Api.where(user_id: @current_user.id).shift if @current_user
    @api_key = "Log in to get your own api token"
    @api_key = user_api.api_key unless user_api.nil?
    @version = 'v1'
    @api_url = "/api/#{@version}"
 end

  def index2
    @current_user = current_user
    user_api = nil #Api.where(user_id: @current_user.id).shift if @current_user
    @api_key = "" #"Log in to get your own api token"
    @api_key = user_api.api_key unless user_api.nil?
    @version = 'v2'
    @api_url = "/api2/#{@version}"
    render template: 'swaggers/index'
  end
end
