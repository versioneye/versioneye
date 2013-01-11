require 'grape'

module VersionEye
  class ProjectsApi < Grape::API
    
    resource :projects do
      desc "check versions of packages in project file"
      get :check do
        "check"
      end
    end
  end
end
