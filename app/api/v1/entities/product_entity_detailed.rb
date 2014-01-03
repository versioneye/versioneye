require_relative 'product_entity'

module EntitiesV1
	class ProductEntityDetailed < ProductEntity
	  expose :group_id, :documentation => {:desc => 'Group id for Java packages'}
	  expose :artifact_id, :documentation => {:desc => 'Artifact id'}

	  expose :license_info, :documentation => {:type => 'string',
	                                      :desc => 'licence of package'}
	  expose :description, :documentation => {:desc => 'description of package'}
	  expose :updated_at, :documentation => {:desc => 'Date of last update'}
	end
end