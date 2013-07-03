class SwaggersController < ApplicationController

  force_ssl

  def index
    @current_user = current_user
    user_api = Api.where(user_id: @current_user.id).shift if @current_user
    @api_key = "Log in to get your own api token"
    @api_key = user_api.api_key unless user_api.nil?
    @version = params.has_key?(:version) ? params[:version] : 'v1'
    @api_url = "/api/#{@version}"
 end

end
