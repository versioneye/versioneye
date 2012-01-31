class FeedbackController < ApplicationController

  def feedback
    name = params[:fb_fullname]
    email = params[:fb_email]
    feedback = params[:feedback]
    p "#{name}, #{email}, #{feedback}"
    if !name.nil? && !name.empty? && !email.nil? && !email.empty? && !feedback.nil? && !feedback.empty?
      p "feedback email " 
      FeedbackMailer.delay.feedback_email(name, email, feedback)
    end    
    respond_to do |format|
      format.js
    end
  end

end