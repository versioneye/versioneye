module UserHelper

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

end
