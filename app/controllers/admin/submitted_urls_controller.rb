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

  def approve
    submitted_url = SubmittedUrl.find_by_id params[:submitted_url_id]
    if submitted_url.nil?
      flash[:error] = "Cant approve: id of SubmittedUrl is missing."
    else
      new_resource = ProductResource.new(:url => params[:url],
                                         :resource_type => params[:resource_type],
                                         :submitted_url => submitted_url,
                                         :declined => false)
      if new_resource.save
        flash[:notice] = "Resource is accepted successfully"
      else
        flash[:error] = new_resource.errors.full_messages.to_sentence
      end
    end

    redirect_to :back
  end

  private 
  
    def admin_user
      redirect_to(root_path) unless signed_in_admin?
    end

end
