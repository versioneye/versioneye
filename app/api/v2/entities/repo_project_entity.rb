require 'grape'
require_relative 'project_entity.rb'
require_relative 'repo_entity'

module EntitiesV2
  class RepoProjectEntity < Grape::Entity
    expose :github, :using => RepoEntity
    expose :projects, :using => ProjectEntity
  end
end
