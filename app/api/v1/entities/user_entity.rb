require 'grape'

module EntitiesV1
	class UserEntity < Grape::Entity
	  expose :fullname
	  expose :username
	end
end