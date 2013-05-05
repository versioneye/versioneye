class UserFactory

  def self.create_new(n = 1, save_db = true)
    user_data = {:username  => "testuser#{n}",
                  :fullname => "Test User#{n}",
                  :email    => "test.user#{n}@versioneye.com",
                  :password => "12345",
                  :terms    => true,
                  :datenerhebung => true,
                  :salt     => "sugar"
                }
    new_user = User.new user_data
    new_user.save if save_db
    
    return new_user
  end

  def self.create_defaults(n = 5)
    1..n.times {|i| UserFactory.create_new(i)}
  end 

  def self.clean_defaults
    rails_mode = "#{ENV['RAILS_ENV']}".strip.downcase.to_sym

    if rails_mode == :test
      User.all.delete_all
      return true
    end

    p "Cant delete Users default_values, because Rails is  in wrong environment: #{rails_mode}."
    return false
  end

  def self.default
    user = User.new
    user.fullname = "Hans Tanz"
    user.username = "hanstanz"
    user.email = "hans@tanz.de"
    user.password = "password"
    user.salt = "salt"
    user.terms = true
    user.datenerhebung = true
    user
  end

end
