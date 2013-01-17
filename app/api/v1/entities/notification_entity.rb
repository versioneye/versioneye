require 'grape'
require_relative 'product_entity.rb'

module VersionEye
  module Entities
    class NotificationEntity < Grape::Entity
      expose :created_at
      expose :version
      expose :product_id, proc: lambda { |obj, options| Product.find_by_id(obj[:product_id]) },
                          using: Entities::ProductEntity,
                          as: "product"
    end
  end
end

