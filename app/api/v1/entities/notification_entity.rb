require 'grape'
require_relative 'product_entity.rb'

module VersionEye
  module Entities
    class NotificationEntity < Grape::Entity
      expose :created_at
      expose :version
      expose :sent_email
      expose :read
      expose :product_id, as: "product", proc: lambda { |obj, options| 
        @product = Product.find_by_id(obj[:product_id])
        ProductEntity.new @product
      }
    end
  end
end

