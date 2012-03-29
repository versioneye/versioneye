class User 
  
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes

  field :username, type: String
  field :fullname, type: String  
  field :email, type: String
  field :encrypted_password, type: String
  field :salt, type: String
  field :admin, type: Boolean, default: false
  field :fb_id, type: String 
  field :fb_token, type: String
  field :verification, type: String
  field :terms, type: Boolean
  field :datenerhebung, type: Boolean
  field :privacy_products, type: String, default: "everybody"
  field :privacy_comments, type: String, default: "everybody"
  
  validates_presence_of :username, :message => "Username is mandatory!"
  validates_presence_of :fullname, :message => "Fullname is mandatory!"
  validates_presence_of :email, :message => "E-Mail is mandatory!"
  validates_presence_of :encrypted_password, :message => "Encrypted_password is mandatory!"
  validates_presence_of :salt, :message => "Salt is mandatory!"
   
  validates_uniqueness_of :username, :message => "Username exist already."
  validates_uniqueness_of :email, :message => "E-Mail exist already."
   
  validates_length_of :username, minimum: 2, maximum: 50, :message => "username length is not ok"
  validates_length_of :fullname, minimum: 2, maximum: 50, :message => "fullname length is not ok"
  #validates_length_of :password, minimum: 5, maximum: 40, :message => "password length is not ok"
   
  validates_format_of :username, with: /^[a-zA-Z0-9]+$/
  validates_format_of :email,    with: /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
  
  attr_accessor :password, :new_username
  attr_accessible :fullname, :username, :email, :password, :new_username, :fb_id, :fb_token, :terms, :datenerhebung, :verification, :terms, :datenerhebung

  before_validation :downcase_email
  
  def save
    encrypt_password if new_record?
    return false if self.terms == false || self.terms == nil
    return false if self.datenerhebung == false || self.datenerhebung == nil
    super
  end
  
  def to_param
    username
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
  
  def create_verification
    random = create_random_value
    self.verification = secure_hash("#{random}--#{username}")
  end
  
  def send_verification_email
    UserMailer.verification_email(self).deliver
  end  
  
  def create_username
    name = fullname.strip
    if name.include?(" ")
      name = name.gsub!(" ", "")
    end
    if name.include?("-")
      name = name.gsub!("-", "")
    end
    user = User.find_by_username(name)
    if user
      name = name + create_random_value
    end
    self.username = name
  end
  
  def self.new_user_email(user)
    UserMailer.new_user_email(user).deliver
  end
  
  def self.activate!(verification)
    user = User.first(conditions: {verification: verification})
    return false if user.nil?
    user.verification = nil
    user.save
  end
  
  def activated?
    return verification.nil?
  end
  
  def self.find_by_username( username )
    User.first(conditions: {username: username} )
  end
  
  def self.find_by_id( id )
    if id.size < 3
      User.find( id.to_i )
    else
      User.find( id )
    end
  rescue
    p "-- ERROR user with id #{id} not found! --"
    nil
  end
  
  def followers
    Follower.find_by_user(self.id)
  end
  
  def fetch_my_products
    notification_ids = Array.new
    ids = Array.new
    followers.each do |follower|
      ids.push follower.product_id
      if follower.notification == true
        notification_ids.push follower.product_id 
      end      
    end  
    result = Array.new
    my_products = Product.any_in(_id: ids).desc(:updated_at)
    my_products.each do |product|
      if notification_ids.include?(product._id.to_s)
        product.notification = true
      end
      result.push product
    end
    result
  end
      
  def fetch_my_product_ids
    ids = Array.new
    followers.each do |follower|
      ids.push follower.product_id
    end
    ids
  end

  def image_url
    url = 'http://www.gravatar.com/avatar/'
    url += Digest::MD5.hexdigest(email.strip.downcase)
    url
  end

  def has_password?(submitted_password)
    self.encrypted_password == encrypt(submitted_password)
  end
  
  def self.find_by_email(email)
    User.first(conditions: {email: email})
  end
  
  def self.find_by_fb_id(fb_id)
    User.first(conditions: {fb_id: fb_id})
  end
  
  def reset_password
    random_value = create_random_value
    self.password = random_value
    encrypt_password
    save
    UserMailer.reset_password(self, random_value).deliver
  end

  def self.authenticate(email, submitted_password)
    user = User.first(conditions: {email: email.downcase} )
    return nil  if user.nil?
    return user if user.has_password?(submitted_password)
  end

  def self.authenticate_with_salt(id, coockie_salt)
    user = User.first( conditions: { id: id } )
    ( user && user.salt == coockie_salt ) ? user : nil
  end
  
  def self.username_valid?(username)
    user = User.first(conditions: { username: username } )
    return user.nil?
  end
  
  def self.email_valid?(email)
    user = find_by_email(email)
    return user.nil?
  end
  
  def update_password(email, password, new_password)
    user = User.authenticate(email, password)
    return false if user.nil?
    self.password = new_password
    encrypt_password
    return save
  end  

  def update_from_fb_json(json_user, token)
    self.fullname = json_user['name']
    self.username = json_user['username']
    self.email = json_user['email']
    self.fb_id = json_user['id']
    self.fb_token = token
    self.password = create_random_value
    if self.username.nil? || self.username.empty?
      self.username = create_random_value
    end
    self.username = self.username.gsub(".", "")
  end
  
  def as_json param
    {
      :fullname => self.fullname,
      :username => self.username
    }
  end
    
  private

    def create_random_value
      chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      value = ""
      10.times { value << chars[rand(chars.size)] }
      value
    end    
    
    def encrypt_password
      self.salt = make_salt if new_record?
      self.encrypted_password = encrypt(password)
    end
    
    def downcase_email
      self.email = self.email.downcase if self.email.present?
    end

    def make_salt
      secure_hash("#{Time.now.utc}--#{password}")
    end

    def encrypt(string)
      secure_hash("#{salt}--#{string}")
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end

end