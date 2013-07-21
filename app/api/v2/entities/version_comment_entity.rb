require 'grape'

require_relative 'user_entity.rb'
require_relative 'product_entity.rb'
require_relative 'paging_entity.rb'

module EntitiesV2
  class VersionCommentEntity < Grape::Entity
    expose :_id, :as => :id
    expose :comment
    expose :created_at
    expose :user, using: UserEntity
    expose :product, using: ProductEntity
  end

  class VersionCommentEntities < Grape::Entity
    expose :comments, using: VersionCommentEntity
    expose :paging, using: PagingEntity
  end
end
