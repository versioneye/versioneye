class Admin::SubmittedUrlsController < ApplicationController

  before_filter :admin_user
  
  def index
    @users = {}
    @submitted_urls = SubmittedUrl.desc(:created_at).paginate(page: params[:page], per_page: 10)
    @submitted_urls.each do |item| 
      user_id = item.user_id 
      @users[user_id] = User.find_by_id(user_id) unless user_id.nil?
    end
  end

  private 
  
    def admin_user
      redirect_to(root_path) unless signed_in_admin?
    end

end