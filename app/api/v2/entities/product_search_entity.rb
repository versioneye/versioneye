require 'grape'

require_relative 'product_entity.rb'
require_relative 'paging_entity.rb'

module EntitiesV2
  class ProductSearchQueryEntity < Grape::Entity
    expose :query    , as: "q"
    expose :languages, as: "lang"
    expose :group_id , as: "g"
  end
  class ProductSearchEntity < Grape::Entity
    expose :query  , using: ProductSearchQueryEntity
    expose :entries, using: ProductEntity, as: "results"
    expose :paging , using: PagingEntity
  end
end

