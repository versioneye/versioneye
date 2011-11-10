# == Schema Information
# Schema version: 20110406010754
#
# Table name: users
#
#  id                 :integer         not null, primary key
#  username           :string(50)      not null
#  fullname           :string(50)      not null
#  email              :string(254)     not null
#  created_at         :datetime
#  updated_at         :datetime
#  encrypted_password :string(255)     not null
#  salt               :string(255)     not null
#  admin              :boolean
#  fb_id              :string(100)
#  fb_token           :string(255)
#

class User < ActiveRecord::Base

  attr_accessor :password, :terms
  attr_accessible :fullname, :username, :email, :fb_id, :password, :terms


  validates :fullname, :presence      => true,
                       :length        => { :within => 2..50 }

  validates :username, :presence      => true,
                       :uniqueness    => true,
                       :length        => { :within => 2..50 }

  validates :email,    :presence    => true,
                       :length      => {:minimum => 5, :maximum => 254},
                       :uniqueness  => true,
                       :format      => {:with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i}

  validates :password, :presence      => true,
                       :length        => { :within => 5..40 }

  validates_acceptance_of  :terms, :message => " - Accepting the Privacy Policy / Terms is mandatory for the registration!"


  has_many :measurements, :dependent => :destroy

  has_many :relationships, :foreign_key => "follower_id", :dependent => :destroy

  has_many :reverse_relationships, :foreign_key => "followed_id",
                                   :class_name => "Relationship",
                                   :dependent => :destroy

  has_many :following, :through => :relationships, :source => :followed

  has_many :followers, :through => :reverse_relationships, :source => :follower

  has_one :geigercounter


  before_save :encrypt_password


  scope :admin, where(:admin => true)


  def to_param
    username
  end

  def image_url
    url = 'http://www.gravatar.com/avatar/'
    url += Digest::MD5.hexdigest(email.strip.downcase)
    url
  end

  def has_password?(submitted_password)
    self.encrypted_password == encrypt(submitted_password)
  end

  def self.authenticate(email, submitted_password)
    user = find_by_email(email)
    return nil  if user.nil?
    return user if user.has_password?(submitted_password)
  end

  def self.authenticate_with_salt(id, coockie_salt)
    user = find_by_id(id)
    ( user && user.salt == coockie_salt ) ? user : nil
  end

  def following?(followed)
    relationships.find_by_followed_id(followed)
  end

  def follow!(followed)
    relationships.create!(:followed_id => followed.id)
  end

  def unfollow!(followed)
    relationships.find_by_followed_id(followed).destroy
  end

  def feed
    Measurement.from_users_followed_by(self)
  end

  def update_from_fb_json (json_user)
    self.fullname = json_user['name']
    self.username = json_user['username']
    self.email = json_user['email']
    self.fb_id = json_user['id']
    self.password = create_random_value
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

    def make_salt
      secure_hash("#{Time.now.utc}--#{password}")
    end

    def encrypt(string)
      p "#{salt}--#{string}"
      secure_hash("#{salt}--#{string}")
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end

end
