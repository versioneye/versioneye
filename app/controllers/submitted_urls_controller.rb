class SubmittedUrlsController < ApplicationController

  def create
    if current_user.nil?
      flash[:error] = 'Sorry, but you have to be logged in for this action'
      redirect_to :back and return
    end

    user_id = current_user.id
    new_submitted_url = SubmittedUrl.new  :user_id      => user_id,
                                          :search_term  => params[:search_term],
                                          :url          => params[:url],
                                          :message      => params[:message]
    if new_submitted_url.save
      flash[:success] = 'Many thanks for your submission. We will integrate it as soon as possible.'
      SubmittedUrlMailer.new_submission_email( new_submitted_url ).deliver_now
    else
      flash[:error] = new_submitted_url.errors.full_messages.to_sentence
    end
    redirect_to :back
  end

end
