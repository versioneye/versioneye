class Testimonial
  require 'will_paginate/array'

  include Mongoid::Document
  include Mongoid::Timestamps

  field :content , type: String
  field :title   , type: String
  field :company , type: String
  field :homepage, type: String
  field :approved, type: Boolean, :default => false
  field :moderated, type: Boolean, :default => false

  belongs_to :user

  index({moderated: -1}, {background: true})


  def self.find_by_id(the_id)
    Testimonial.all.where(_id: the_id).first
  end

  def self.dummy_data
    p '#-- generating dummy testimonials'
    counter = 0
    n = Testimonial.all.count

    User.all.skip(n).each do |user|
      Testimonial.create content: 'Boom-boom, i am Daddy Cool!',
                        title: 'Mr.President',
                        company: 'Rich daddy',
                        user_id: user.id
      return if counter > 10
      counter += 1
    end
  end

end
