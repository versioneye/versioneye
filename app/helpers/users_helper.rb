module UsersHelper

  include ActionView::Helpers::TextHelper

  def gravatar_for(user, options = { :size => 50 })
    gravatar_image_tag(user.email.downcase, :alt => user.fullname,
                                            :class => 'gravatar',
                                            :gravatar => options)
  end

  def gravatar_mes_for(user, options = { :size => 150 })
    gravatar_image_tag(user.email.downcase, :alt => user.fullname,
                                            :class => 'gravatar',
                                            :gravatar => options)
  end

  def has_permission_to_see_products( user, current_user )
    return false if user.nil?
    return true  if !current_user.nil? && user.id == current_user.id

    if user.privacy_products.eql?('nobody')
      return false
    elsif user.privacy_products.eql?('ru')
      return true if !current_user.nil?
      return false if current_user.nil?
    elsif user.privacy_products.eql?('everybody')
      return true
    end
    true
  end

  def has_permission_to_see_comments( user, current_user )
    return true if !current_user.nil? && user.id == current_user.id
    if user.privacy_comments.eql?('nobody')
      return false
    elsif user.privacy_comments.eql?('ru')
      return true if !current_user.nil?
      return false if current_user.nil?
    elsif user.privacy_comments.eql?('everybody')
      return true
    end
    true
  end

  def username_max_30 username
    if username.to_s.length > 30
      part = username.to_s[0..28]
      return "#{part}.."
    end
    username
  end

end
