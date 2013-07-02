require 'grape'

require 'user_entity.rb'
require 'product_entity.rb'
require 'paging_entity.rb'

module EntitiesV1
	class UserFollowEntity < Grape::Entity
	  expose :username
	  expose :prod_key
	  expose :follows
	end

	class UserFollowEntities < Grape::Entity
	  expose :user, using: UserEntity
	  expose :favorites, using: ProductEntity
	  expose :paging, using: PagingEntity
	end
end
