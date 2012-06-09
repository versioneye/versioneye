class FeedbackController < ApplicationController

  def feedback
    name = params[:fb_fullname]
    email = params[:fb_email]
    feedback = params[:feedback]
    math = params[:fb_math]
    
    if !name.nil? && !name.empty? && !email.nil? && !email.empty? && !feedback.nil? && !feedback.empty?
      if signed_in? || math.eql?("9")
        FeedbackMailer.feedback_email(name, email, feedback).deliver
      end
    end    
    respond_to do |format|
      format.js
    end
  end

end