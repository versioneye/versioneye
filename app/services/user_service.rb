class UserService
  
  def self.search(term)
    EsUser.search(term)
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    return nil
  end

  def self.create_random_token(length = 25)
    SecureRandom.urlsafe_base64(length)
  end

  def self.valid_user?(user, flash, t)
    if !User.email_valid?(user.email)
      flash[:error] = "page_signup_error_email"
      return false;
    elsif user.fullname.nil? || user.fullname.empty?
      flash[:error] = "page_signup_error_fullname"
      return false;
    elsif user.password.nil? || user.password.empty? || user.password.size < 5
      flash[:error] = "page_signup_error_password"
      return false;
    elsif user.terms != true
      flash[:error] = "page_signup_error_terms"
      return false;
    end
    return true;
  end

end
