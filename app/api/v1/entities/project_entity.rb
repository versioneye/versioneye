require 'grape'
require_relative 'project_dependency_entity.rb'

module VersionEye
  module Entities
    class ProjectEntity < Grape::Entity
      expose :_id, :as => :id 
      expose :name
      expose :project_type
      expose :private_project, :as => :private
      expose :perion
      expose :source
      expose :dep_number
      expose :out_number
      expose :created_at
      expose :updated_at
      expose :dependencies, :using => ProjectDependencyEntity, :if => { :type => :full} 
    end

  end
end
