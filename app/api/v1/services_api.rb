require 'grape'

module VersionEye
  class ServicesApi < Grape::API

    resource :services do
      desc "Answers to request with basic pong."
      get :ping do
        "pong"
      end
    end

  end
end
