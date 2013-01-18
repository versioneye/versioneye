class ApiFactory
  def self.create_new(user = nil, save = true)
    user = UserFactory.create_new(101) if user.nil?
   
    if user.nil?
      p "User is not specified or cant create random test-user"
      p user.errors.full_messages.to_sentence
      return nil
    end
    new_api_key = Api.generate_api_key
    @user_api = Api.new user_id: user.id, api_key: new_api_key

    if save 
      unless @user_api.save
        p @user_api.errors.full_messages.to_sentence
      end
    end
    @user_api
  end

end
