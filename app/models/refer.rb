class Refer

	include Mongoid::Document
	include Mongoid::Timestamps

	field :name, type: String
	field :description, type: String
	field :count, type: Integer, default: 0

	def self.get_by_name(name)
		sources = Refer.where(name: name)
		sources[0]
	end

end