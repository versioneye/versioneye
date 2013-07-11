class UserTestimonial
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :content, type: String
  field :title, type: String

  scope :by_user, ->(the_user){where(user_id: the_user.id)}
  def self.find_by_id(the_id)
    UserTestimonial.all.where(_id: the_id).first
  end

end
