class User < ActiveRecord::Base

  attr_accessor :password, :terms, :datenerhebung, :new_username
  attr_accessible :fullname, :username, :email, :password, :new_username, :fb_id, :fb_token, :terms, :datenerhebung, :verification

  validates :fullname, :presence      => true,
                       :length        => {:within => 2..50}

  validates :username, :presence      => true,
                       :uniqueness    => true,
                       :length        => {:within => 2..50},
                       :format        => {:with => /^[a-zA-Z0-9]+$/}

  validates :email,    :presence    => true,
                       :length      => {:minimum => 5, :maximum => 254},
                       :uniqueness  => true,
                       :format      => {:with => /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/}

  validates :password, :presence      => true,
                       :length        => { :within => 5..40 }

  validates_acceptance_of  :terms, :message => " - Accepting the Privacy Policy / Terms is mandatory for the registration!"
  validates_acceptance_of  :datenerhebung, :message => " - Accepting the Datenerhebung is mandatory for the registration!"

  has_many :followers, :foreign_key => "user_id", :dependent => :destroy
  has_many :notifications, :dependent => :destroy
  has_many :versioncomments, :dependent => :destroy

  before_validation :downcase_email
  before_save :encrypt_password
  

  scope :admin, where(:admin => true)

  def to_param
    username
  end
  
  def create_verification
    random = create_random_value
    self.verification = secure_hash("#{random}--#{username}")
  end
  
  def send_verification_email
    # UserMailer.verification_email(self).deliver
    UserMailer.delay.verification_email(self) # use delayed_job to do it later
  end  
  
  def self.activate!(verification)
    user = User.find(:first, :conditions => ["verification = ?", verification])
    return false if user.nil?
    # this method call skipps the callbacks. The filters are not called by this method call! 
    return user.update_column(:verification, nil)
  end
  
  def activated?
    return verification.nil?
  end
  
  def fetch_my_products
    ids = fetch_my_product_ids
    result = Product.find(ids)
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
    user = User.find(:first, :conditions => ["email = ?", email])
    user
  end
  
  def self.find_by_fb_id(fb_id)
    user = User.find(:first, :conditions => ["fb_id = ?", fb_id])
    user
  end
  
  def reset_password
    random_value = create_random_value
    self.password = random_value
    encrypt_password
    update_column(:encrypted_password, self.encrypted_password)
    # UserMailer.reset_password(self).deliver
    UserMailer.delay.reset_password(self, random_value)
  end

  def self.authenticate(email, submitted_password)
    user = User.find(:first, :conditions => ["email = ?", email.downcase])
    return nil  if user.nil?
    return user if user.has_password?(submitted_password)
  end

  def self.authenticate_with_salt(id, coockie_salt)
    user = User.find(:first, :conditions => ["id = ?", id])
    ( user && user.salt == coockie_salt ) ? user : nil
  end
  
  def self.username_valid?(username)
    user = User.find(:first, :conditions => ["username = ?", username])
    return user.nil?
  end
  
  def self.email_vaild?(email)
    user = find_by_email(email)
    return user.nil?
  end
  
  def update_password(email, password, new_password)
    user = User.authenticate(email, password)
    return false if user.nil?
    user.password = new_password
    return user.save
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