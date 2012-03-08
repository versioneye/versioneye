class Blog

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes # Need for type: DateTime 

  field :subject, type: String
  field :post, type: String
  field :user_id, type: Integer
  field :approved, type: Boolean
  field :reason, type: String 
  
  validates_inclusion_of :approved, :in => [true, false, nil]
  validates_presence_of :user_id, :message => "User is mandatory!"
  validates_presence_of :subject, :message => "You have to type in a subject!"
  validates_presence_of :post, :message =>  "You have to type in a post message!"
  
  def self.find_approved_posts
    Blog.where(approved: true ).desc(:created_at).limit(30)
  end
  
  def self.find_unapproved_posts
    Blog.where(approved: nil ).desc(:created_at).limit(30)
  end
  
  def self.find_user_posts user_id
    Blog.where( user_id: user_id).desc(:created_at)
  end
  
  def post_html
    if !self.post.nil? && !self.post.empty?
      result = self.post.gsub!("\n", "<br/>")
      return self.post.html_safe if result.nil?
      return result.html_safe unless result.nil?
    end
    ""
  end
  
  def get_user
    User.find(self.user_id)
  end
  
end