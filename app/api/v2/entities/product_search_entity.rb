require 'grape'

require_relative 'product_entity.rb'
require_relative 'paging_entity.rb'

module V2
  module Entities
    class ProductSearchQueryEntity < Grape::Entity
      expose :query    , as: "q"
      expose :languages, as: "lang"
      expose :group_id , as: "g"
    end
    class ProductSearchEntity < Grape::Entity
      expose :query  , using: Entities::ProductSearchQueryEntity
      expose :entries, using: Entities::ProductEntity, as: "results"
      expose :paging , using: Entities::PagingEntity
    end
  end
end
