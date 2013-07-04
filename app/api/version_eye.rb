require 'grape'

module VersionEye
	class API < Grape::API
    mount V1::ApiV1 => '/v1'
		mount V2::ApiV2 => '/v2'
	end
end