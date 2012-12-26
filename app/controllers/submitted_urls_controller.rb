class SubmittedUrlsController < ApplicationController

  def create
    success = false
    user_id = current_user.id unless current_user.nil?
    new_submitted_url = SubmittedUrl.new  :user_id      => user_id, 
                                          :search_term  => params[:search_term],
                                          :url          => params[:url],
                                          :user_email   => params[:user_email],
                                          :message      => params[:message]
    
    if !signed_in? 
      if params[:fb_math].nil?
        flash[:error] = "You have to solve the math!"
        redirect_to :back
        return   
      end

      captcha_result = params[:value_a].to_i + params[:value_b].to_i
      submitted_result = params[:fb_math].to_i
      if submitted_result != captcha_result
        flash[:error] = "You have to solve the math correct!"
        redirect_to :back
        return   
      end
    end
    
    if new_submitted_url.save
      flash[:success] = "Many thanks for your submission. We will integrate it as soon as possible."
    else
      flash[:error] = new_submitted_url.errors.full_messages.to_sentence
    end

    redirect_to :back
  end

end
