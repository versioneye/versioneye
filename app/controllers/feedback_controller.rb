class FeedbackController < ApplicationController

  def feedback
    name = params[:fb_fullname]
    email = params[:fb_email]
    feedback = params[:feedback]
    if name && !name.empty? && email && !email.empty? && feedback && !feedback.empty?
      FeedbackMailer.feedback_email(name, email, feedback).deliver
    end
    respond_to do |format|
      format.js
    end
  end

end
