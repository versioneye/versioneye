require 'grape-entity'

module EntitiesV2
  class RepoEntity < Grape::Entity
    expose :name             , :documentation => {type: 'string',  desc: 'name of repo'}
    expose :fullname         , :documentation => {type: 'string',  desc: 'repo owner and repo name'}
    expose :language         , :documentation => {type: 'string',  desc: 'the main programming language'}
    expose :repo_key         , :documentation => {type: 'string',  desc: 'decoded repo key'}
    expose :owner_login      , :documentation => {type: 'string',  desc: 'the name of owner of repository'}
    expose :owner_type       , :documentation => {type: 'string',  desc: "the type of owner's organization"}
    expose :description      , :documentation => {type: 'string',  desc: 'the description of repository'}
    expose :private          , :documentation => {type: 'boolean', desc: 'the flag of visibility'}
    expose :fork             , :documentation => {type: 'boolean', desc: 'the flag of origin'}
    expose :branches         , :documentation => {type: 'array',   desc: 'list of branches'}
    expose :imported_projects, :documentation => {type: 'array',   desc: "list of imported project's keys"}
  end

  class RepoEntityDetailed < RepoEntity
    expose :git_url   , :documentation => {type: 'string',  desc: 'scm uri'}
    expose :html_url  , :documentation => {type: 'string',  desc: 'www uri'}
    expose :created_at, :documentation => {type: 'Date',    desc: 'the date of creation'}
    expose :cached_at , :documentation => {type: 'Date',    desc: 'the date of last sync'}
    expose :size      , :documentation => {type: 'integer', desc: 'the size of repo'}
    expose :homepage  , :documentation => {type: 'string',  desc: 'the homepage'}
  end
end
