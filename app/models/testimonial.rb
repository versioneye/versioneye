class Testimonial

  include Mongoid::Document
  include Mongoid::Timestamps

  field :content , type: String
  field :title   , type: String
  field :company , type: String
  field :approved, type: Boolean, :default => false

  belongs_to :user

  def self.find_by_id(the_id)
    UserTestimonial.all.where(_id: the_id).first
  end

end
