class FeedbackController < ApplicationController

  def feedback
    name = params[:fb_fullname]
    email = params[:fb_email]
    feedback = params[:feedback]
    math = params[:fb_math]
    value_a = params[:value_a]
    value_b = params[:value_b]

    if name && !name.empty? && email && !email.empty? && feedback && !feedback.empty?
      @correct_math = false
      if math && value_b && value_a
        correct_result = value_a.to_i + value_b.to_i
        if correct_result == math.to_i 
          @correct_math = true 
        end
      end
      if @correct_math
        FeedbackMailer.feedback_email(name, email, feedback).deliver
      end
    end    
    respond_to do |format|
      format.js
    end
  end

end