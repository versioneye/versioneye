require 'grape'

require 'user_entity.rb'
require 'product_entity.rb'
require 'paging_entity.rb'

module EntitiesV2
  class UserFollowEntities < Grape::Entity
    expose :user, using: UserEntity
    expose :favorites, using: ProductEntity
    expose :paging, using: PagingEntity
  end
end
