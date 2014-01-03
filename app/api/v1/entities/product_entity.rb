require 'grape-entity'

module EntitiesV1
  class ProductEntity < Grape::Entity
    expose :name, :documentation => {:type => 'string',
                                     :desc => 'name of package'}
    expose :prod_key, :documentation => {:type => 'string',
                                         :desc => 'product key for given package'}
    expose :prod_type, :documentation => {:type => 'string',
                                          :desc => 'product type of package'}
    expose :version, :documentation => {:desc => 'Latest version'}
    expose :language, :documentation => {:desc => 'Programming language'}
  end

  class ProductEntityDetailed < ProductEntity
    expose :group_id, :documentation => {:desc => 'Group id for Java packages'}
    expose :artifact_id, :documentation => {:desc => 'Artifact id'}

    expose :license_info, :documentation => {:type => 'string',
                                        :desc => 'licence of package'}
    expose :description, :documentation => {:desc => 'description of package'}
    expose :updated_at, :documentation => {:desc => 'Date of last update'}
  end
end
