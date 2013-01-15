require 'grape'
require_relative 'user_entity.rb'
require_relative 'product_entity.rb'

module VersionEye
  module Entities
    class VersionCommentEntity < Grape::Entity
      expose :_id, :as => :id
      expose :comment
      expose :created_at
      expose :user, using: UserEntity 
      expose :product, using: ProductEntity
    end
  end
end
