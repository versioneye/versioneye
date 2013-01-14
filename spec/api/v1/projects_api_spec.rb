require 'spec_helper'
require 'rest_client'

describe VersionEye::ProjectsApi do
  describe "Uploading new project" do
    include Rack::Test::Methods

    @new_project = nil

    before(:each) do
      file_path =  "#{Rails.root}/test/files/maven-1.0.1.pom"
      @test_file1 = Rack::Test::UploadedFile.new(file_path, "text/xml")
    end

    it "fails, when upload-file is missing" do
      post "/v1/projects"
      response.status.should eql(403)
    end

    it "returns 201 and project info, when upload was successfully" do
      r = RestClient.post "http://127.0.0.1:3000/v1/projects", "upload" => @test_file1
      r.code.should eql(201)
    end
  end
end
