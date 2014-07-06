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

  def check_promo_code( code, user )
    return nil if code.to_s.empty? || user.nil?
    promo = PromoCode.by_name code
    if promo.nil?
      flash.now[:warn] = 'Sorry. But the promo code you entered does not exist!'
    elsif !promo.is_valid?
      flash.now[:warn] = 'Sorry. But the promo code you entered is not valid anymore!'
    else
      promo.redeem!
      user.free_private_projects = promo.free_private_projects
      user.promo_code = code
      user.save
      plu = pluralize(promo.free_private_projects, 'private project')
      flash.now[:success] = "Congrats. Because of the promo code you can monitor #{plu} for free!"
    end
  rescue => e
    logger.error "ERROR in check_promo_code: #{e.message}"
    logger.error e.backtrace.join "\n"
    nil
  end

end
