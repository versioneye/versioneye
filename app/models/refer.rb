class Refer

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :count, type: Integer, default: 0

  def self.get_by_name(name)
    Refer.where(name: name).shift
  end

end
