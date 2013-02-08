class SubmittedUrlsController < ApplicationController

  def create
    success = false
    user_id = current_user.id unless current_user.nil?
    new_submitted_url = SubmittedUrl.new  :user_id      => user_id, 
                                          :search_term  => params[:search_term],
                                          :url          => params[:url],
                                          :message      => params[:message]
    if new_submitted_url.save
      flash[:success] = "Many thanks for your submission. We will integrate it as soon as possible."
    else
      flash[:error] = new_submitted_url.errors.full_messages.to_sentence
    end
    redirect_to :back
  end

end
