require 'grape'

require 'user_entity.rb'
require 'product_entity.rb'
require 'paging_entity.rb'


module VersionEye
  module Entities
    class UserFollowEntity < Grape::Entity
      expose :username
      expose :prod_key
      expose :follows
    end

    class UserFollowEntities < Grape::Entity
      expose :user, using: Entities::UserEntity
      expose :favorites, using: Entities::ProductEntity
      expose :paging, using: Entities::PagingEntity
    end
  end
end
