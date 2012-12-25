class SubmittedUrlsController < ApplicationController
  
  def index
    @users = {}
    @submitted_urls = SubmittedUrl.desc(:created_at)
    @submitted_urls.each do |item| 
        @users[item.user_id] = User.find_by_id(item.user_id) unless item.user_id.nil?
    end
  end

  def create
    success = false
    user_id = current_user.id unless current_user.nil?
    new_submitted_url = SubmittedUrl.new  :user_id    => user_id, 
                                          :url        => params[:url],
                                          :user_email => params[:user_email],
                                          :message    => params[:message]
    captcha_result = params[:value_a].to_i + params[:value_b].to_i
    
    if current_user 
      success = new_submitted_url.save
    elsif (not params[:fb_math].nil? and (captcha_result == params[:fb_math].to_i) )
       success = new_submitted_url.save
    end
    if success
      flash[:notice] = "Many thanks for your submission. We will integrate it is soon as possible."
    else
      flash[:error] = "An error occurred - Please try again later."
    end

    redirect_to :back
  end

end
