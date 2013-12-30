require 'grape'


class ServicesApiV1 < Grape::API

	resource :services do
	  desc 'Answers to request with basic pong.'
	  get :ping do
	    {success: true, message: 'pong'}
	  end
	end

end
