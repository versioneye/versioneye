class UserService

  def self.search(term)
    EsUser.search( term )
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    return []
  end

  def self.create_random_token(length = 25)
    SecureRandom.urlsafe_base64(length)
  end

  def self.valid_user?(user, flash)
    unless User.email_valid?(user.email)
      flash[:error] = 'page_signup_error_email'
      return false
    end
    if user.fullname.nil? || user.fullname.empty?
      flash[:error] = 'page_signup_error_fullname'
      return false
    elsif user.password.nil? || user.password.empty? || user.password.size < 5
      flash[:error] = 'page_signup_error_password'
      return false
    elsif !user.terms
      flash[:error] = 'page_signup_error_terms'
      return false
    end
    true
  end

  def self.delete user
    Notification.remove_notifications user
    collaborators = ProjectCollaborator.by_user user
    if !collaborators.nil? && !collaborators.empty?
      collaborators.each do |project_collaborator|
        project_collaborator.remove
      end
    end
    StripeService.delete user.stripe_customer_id
    random              = create_random_value
    user.deleted        = true
    user.email          = "#{random}_#{user.email}"
    user.prev_fullname  = user.fullname
    user.fullname       = 'Deleted'
    user.username       = "#{random}_#{user.username}"
    user.github_id      = nil
    user.github_token   = nil
    user.github_scope   = nil
    user.twitter_id     = nil
    user.twitter_token  = nil
    user.twitter_secret = nil
    user.products.clear
    user.save
  end

  def self.active_users
    User.all.select do |user|
      ( (!user['product_ids'].nil? && user['product_ids'].count > 0) or
       Versioncomment.where(user_id: user.id).exists? or
       Project.where(user_id: user.id).exists?
      )
    end
  end

  def self.create_random_value
    chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    value = ''
    10.times { value << chars[rand(chars.size)] }
    value
  end

end
