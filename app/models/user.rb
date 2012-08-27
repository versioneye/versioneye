class User 
  
  require 'will_paginate/array'
  
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes

  field :old_id, type: String
  field :username, type: String
  field :fullname, type: String
  field :prev_fullname, type: String
  field :email, type: String
  field :encrypted_password, type: String
  field :salt, type: String
  field :admin, type: Boolean, default: false
  field :deleted, type: Boolean, default: false
  field :verification, type: String
  field :terms, type: Boolean
  field :datenerhebung, type: Boolean
  field :privacy_products, type: String, default: "everybody"
  field :privacy_comments, type: String, default: "everybody"

  field :description, type: String
  field :location, type: String
  field :time_zone, type: String
  field :blog, type: String
  field :background_color, type: String

  field :fb_id, type: String 
  field :fb_token, type: String

  field :twitter_id, type: String
  field :twitter_token, type: String
  field :twitter_secret, type: String
  
  field :github_id, type: String 
  field :github_token, type: String
  field :github_scope, type: String

  field :stripe_token, type: String
  field :stripe_customer_id, type: String
  field :plan_name_id, type: String, default: "01_free"
  
  validates_presence_of :username, :message => "Username is mandatory!"
  validates_presence_of :fullname, :message => "Fullname is mandatory!"
  validates_presence_of :email, :message => "E-Mail is mandatory!"
  validates_presence_of :encrypted_password, :message => "Encrypted_password is mandatory!"
  validates_presence_of :salt, :message => "Salt is mandatory!"
   
  validates_uniqueness_of :username, :message => "Username exist already."
  validates_uniqueness_of :email, :message => "E-Mail exist already."
   
  validates_length_of :username, minimum: 2, maximum: 50, :message => "username length is not ok"
  validates_length_of :fullname, minimum: 2, maximum: 50, :message => "fullname length is not ok"
   
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
    UserMailer.verification_email(self, self.verification, self.email).deliver
  end  

  def self.send_verification_reminders
    users = User.all(conditions: {verification: {"$ne" => nil}})
    users.each do |user|
      user.send_verification_reminder  
    end
  end 

  def send_verification_reminder 
    if !self.verification.nil? && self.deleted != true
      UserMailer.verification_email_reminder(self, self.verification, self.email).deliver
    end
  rescue 
    p "ups. Something went wrong for #{self.fullname}"
  end

  def plan
    Plan.first(conditions: {name_id: self.plan_name_id})
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
    if user 
      user.verification = nil
      user.save
      return true
    end
    return false;
  end
  
  def activated?
    return verification.nil?
  end
  
  def self.find_by_username( username )
    User.first(conditions: {username: /^#{username}$/i} )
  end
  
  def self.find_by_id( id )
    User.find( id )
  rescue
    logger.error "-- ERROR user with id #{id} not found! --"
    nil
  end

  def self.find_by_ids( ids )
    User.all(conditions: {:_id.in => ids})
  rescue
    logger.error "-- ERROR user with id #{id} not found! --"
    nil
  end

  def emails
    UserEmail.all(conditions: {user_id: self._id.to_s})
  end

  def emails_verified
    UserEmail.all(conditions: {user_id: self._id.to_s, verification: nil})
  end

  def get_email(email)
    UserEmail.first(conditions: {user_id: self._id.to_s, email: email})
  end
  
  def followers
    Follower.find_by_user(self.id)
  end
  
  def fetch_my_products
    ids = Array.new
    followers.each do |follower|
      ids.push follower.product_id
    end  
    Product.any_in(_id: ids).desc(:updated_at)
  end

  def fetch_my_products_count
    notification_ids = Array.new
    ids = Array.new
    followers.each do |follower|
      ids.push follower.product_id
      if follower.notification == true
        notification_ids.push follower.product_id 
      end      
    end  
    Product.any_in(_id: ids).count()
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
    User.first(conditions: {email: /^#{email}$/i})
  end
  
  def self.find_by_fb_id(fb_id)
    User.first(conditions: {fb_id: fb_id})
  end

  def self.find_by_twitter_id(twitter_id)
    User.first(conditions: {twitter_id: twitter_id})
  end
  
  def self.find_by_github_id(github_id)
    User.first(conditions: {github_id: github_id})
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
    return nil  if user.nil? || user.deleted
    return user if user.has_password?(submitted_password)
  end

  def self.authenticate_with_salt(id, coockie_salt)
    user = User.first( conditions: { id: id } )
    ( user && user.salt == coockie_salt ) ? user : nil
  end
  
  def self.username_valid?(username)
    user = User.find_by_username(username)
    return user.nil?
  end
  
  def self.email_valid?(email)
    user = find_by_email(email)
    return user.nil?
  end

  def password_valid?(password)
    enc_password = encrypt(password)
    enc_password.eql?(encrypted_password)
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
    self.verification = nil
    self.fb_id = json_user['id']
    self.fb_token = token
    self.password = create_random_value
    if self.username.nil? || self.username.empty?
      self.username = create_random_value
    end
    self.username = replacements_for_username( self.username )
    if self.fullname.nil? || self.fullname.empty?
      self.fullname = self.username
    end
  end

  def update_from_twitter_json(json_user, token, secret)
    self.fullname = json_user['name']
    self.username = json_user['screen_name']
    self.description = json_user['description']
    self.location = json_user['location']
    self.time_zone = json_user['time_zone']
    self.blog = json_user['url']
    self.background_color = json_user['profile_background_color']
    self.twitter_id = json_user['id']
    self.twitter_token = token
    self.twitter_secret = secret
    self.password = create_random_value
    if self.username.nil? || self.username.empty?
      self.username = create_random_value
    end
    self.username = replacements_for_username( self.username )
    if self.fullname.nil? || self.fullname.empty?
      self.fullname = self.username
    end
  end
  
  def update_from_github_json(json_user, token)
    self.fullname = json_user['name']
    self.username = json_user['login']
    self.github_id = json_user['id']
    self.github_token = token
    self.github_scope = "repo"
    self.password = create_random_value
    if self.username.nil? || self.username.empty?
      self.username = create_random_value
    end
    user = User.find_by_username(self.username)
    if !user.nil?
      random_value = create_random_value
      self.username = "#{self.username}#{random_value}"
    end
    self.username = replacements_for_username( self.username )
    if self.fullname.nil? || self.fullname.empty?
      self.fullname = self.username
    end
  end

  def replacements_for_username( username )
    username = username.gsub(".", "")
    username = username.gsub("-", "")
    username = username.gsub("_", "")
    username
  end
  
  def as_json param
    {
      :fullname => self.fullname,
      :username => self.username
    }
  end

  def delete_user
    random = create_random_value
    self.deleted = true
    self.email = "#{random}_#{self.email}"
    self.prev_fullname = self.fullname
    self.fullname = "Deleted"
    self.save
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