require 'grape'

module V2
  module Entities
  
    class ProjectDependencyEntity < Grape::Entity
      expose :name
      expose :prod_key
      expose :group_id
      expose :artifact_id

      expose :version_current
      expose :version_requested

      expose :comperator, :as => :comparator
      expose :unknown?, :as => :unknown
      expose :outdated?, :as => :outdated
      expose :release, :as => :stable 
    end

  end
end

