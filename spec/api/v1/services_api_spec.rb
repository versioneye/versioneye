require 'spec_helper'

describe VersionEye::ServicesApi do
  describe "GET /v1/services/ping" do
    it "answers `pong`" do
      get '/api/v1/services/ping.json'
      response.status.should == 200
      response_body.should eql("pong")
    end
  end
end
