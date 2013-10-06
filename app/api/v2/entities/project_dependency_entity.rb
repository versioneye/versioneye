require 'grape'

module EntitiesV2
  class ProjectDependencyEntity < Grape::Entity
    expose :name
    expose :prod_key
    expose :group_id
    expose :artifact_id
    expose :license

    expose :version_current
    expose :version_requested

    expose :comperator, :as => :comparator
    expose :unknown?  , :as => :unknown
    expose :outdated? , :as => :outdated
    expose :release   , :as => :stable
  end
end
