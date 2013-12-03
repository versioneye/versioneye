class SwaggersController < ApplicationController

  def index
    @current_user = current_user
    user_api = Api.where(user_id: @current_user.id).shift if @current_user
    @api_key = "Log in to get your own api token"

    if @current_user.nil? == false and @api_key.nil?
      user_api = Api.create_new(@current_user)
    end

    @api_key = user_api.api_key unless user_api.nil?
    @version = params.has_key?(:version) ? params[:version] : 'v2'
    @api_url = "/api/#{@version}"
  end

end
