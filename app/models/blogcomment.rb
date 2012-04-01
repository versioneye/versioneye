class Blogcomment

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes # Need for type: DateTime 

  field :blog_id, type: String
  field :comment, type: String
  field :user_id, type: Integer
  field :username, type: String
  field :approved, type: Boolean
  
  validates_presence_of :comment, :message => "Comment is mandatory!"
  
  attr_accessor :user_obj
  
  def comment_html
    if !self.comment.nil? && !self.comment.empty?
      result = self.comment.gsub!("\n", "<br/>")
      return self.comment.html_safe if result.nil?
      return result.html_safe unless result.nil?
    end
    ""
  end
  
  def blog
    Blog.find(self.blog_id)
  end
  
  def user
    if self.user_obj.nil?
      p "load user for comment"
      self.user_obj = User.find(self.user_id)
    end
    self.user_obj
  end
  
end