class FeedbackController < ApplicationController

  def feedback
    name = params[:fb_fullname]
    email = params[:fb_email]
    feedback = params[:feedback]
    if !name.nil? && !name.empty? && !email.nil? && email.empty? && !feedback.nil? && !feedback.empty?
      FeedbackMailer.delay.feedback_email(name, email, feedback)
    end    
    respond_to do |format|
      format.js
    end
  end

end