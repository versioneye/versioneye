require 'grape'

module V2
  class V2ServicesApi < Grape::API

    resource :services do
      desc "Answers to request with basic pong."
      get :ping do
        {success: true, message: "pong"}
      end
    end

  end
end
