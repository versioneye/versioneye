require 'grape'

module EntitiesV2
  class UserFollowEntity < Grape::Entity
    expose :username
    expose :prod_key
    expose :follows
  end
end
