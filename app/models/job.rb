class Job

	# TODO where used ?

	include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::MultiParameterAttributes

	field :title, type: String
	field :mandant, type: String
	field :link, type: String
	field :start, type: DateTime
	field :stop, type: DateTime
	field :location, type: String
	field :summary, type: String

end
