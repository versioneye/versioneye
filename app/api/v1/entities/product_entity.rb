require 'grape'

module VersionEye
  module Entities
    class ProductEntity < Grape::Entity
      expose :name, :documentation => {:type => "string", 
                                       :desc => "name of package"}
      expose :prod_key, :documentation => {:type => "string", 
                                           :desc => "product key for given package"}
      expose :prod_type, :documentation => {:type => "string",
                                            :desc => "product type of package"}
      expose :lang, :documentation => {:desc => "Programming language"}    

    end

    class ProductEntityDetailed < Entities::ProductEntity
      expose :group_id, :documentation => {:desc => "Group id for Java packages"}
      expose :artifact_id, :documentation => {:desc => "Artifact id"}

      expose :licence, :documentation => {:type => "string",
                                          :desc => "licence of package"}
      expose :description, :documentation => {:desc => "description of package"}
      expose :version, :documentation => {:desc => "Latest version"}
      expose :updated_at, :documentation => {:desc => "Date of last update"}

    end
  end
end
