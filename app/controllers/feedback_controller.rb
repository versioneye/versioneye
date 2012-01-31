class FeedbackController < ApplicationController

  def feedback
    name = params[:fb_fullname]
    email = params[:fb_email]
    feedback = params[:feedback]
    FeedbackMailer.delay.feedback_email(name, email, feedback)
    respond_to do |format|
      format.js
    end
  end

end