class Userlinkcollection

  include Mongoid::Document
  include Mongoid::Timestamps

  A_LINKEDIN      = 'http://www.linkedin.com/in/'
  A_XING          = 'http://www.xing.com/profile/'
  A_GITHUB        = 'https://github.com/'
  A_STACKOVERFLOW = 'http://stackoverflow.com/users/'
  A_TWITTER       = 'https://twitter.com/#!/'
  A_FACEBOOK      = 'http://www.facebook.com/people/'

  field :user_id,       type: String
  field :linkedin,      type: String, :default => A_LINKEDIN
  field :xing,          type: String, :default => A_XING
  field :github,        type: String, :default => A_GITHUB
  field :stackoverflow, type: String, :default => A_STACKOVERFLOW
  field :twitter,       type: String, :default => A_TWITTER
  field :facebook,      type: String, :default => A_FACEBOOK

  def self.find_all_by_user(user_id)
    return nil if user_id.nil? || user_id.to_s.strip.empty?
  	Userlinkcollection.where( user_id: user_id ).shift
  end

  def empty?
  	linkedin_empty? && xing_empty? && github_empty? &&
    stackoverflow_empty? && twitter_empty? && facebook_empty?
  end

  def convert_to_abs
    if self.linkedin && !self.linkedin.empty?
      self.linkedin = "#{A_LINKEDIN}#{self.linkedin}"
    end
    if self.xing && !self.xing.empty?
      self.xing = "#{A_XING}#{self.xing}"
    end
    if self.github && !self.github.empty?
      self.github = "#{A_GITHUB}#{self.github}"
    end
    if self.stackoverflow && !self.stackoverflow.empty?
      self.stackoverflow = "#{A_STACKOVERFLOW}#{self.stackoverflow}"
    end
    if self.twitter && !self.twitter.empty?
      self.twitter = "#{A_TWITTER}#{self.twitter}"
    end
    if self.facebook && !self.facebook.empty?
      self.facebook = "#{A_FACEBOOK}#{self.facebook}"
    end
    self.save()
  end

  def linkedin_empty?
    self.linkedin.nil? || self.linkedin.empty? || self.linkedin.eql?(A_LINKEDIN)
  end
  def xing_empty?
    self.xing.nil? || self.xing.empty? || self.xing.eql?(A_XING)
  end
  def github_empty?
    self.github.nil? || self.github.empty? || self.github.eql?(A_GITHUB)
  end
  def stackoverflow_empty?
    self.stackoverflow.nil? || self.stackoverflow.empty? || self.stackoverflow.eql?(A_STACKOVERFLOW)
  end
  def twitter_empty?
    self.twitter.nil? || self.twitter.empty? || self.twitter.eql?(A_TWITTER)
  end
  def facebook_empty?
    self.facebook.nil? || self.facebook.empty? || self.facebook.eql?(A_FACEBOOK)
  end

end
