require 'spec_helper'
require 'rest_client'

describe VersionEye::ProjectsApi do

  let( :root_uri    ) { "/api/v1" }
  let( :project_uri ) { "/api/v1/projects" }
  let( :test_user   ) { UserFactory.create_new(90) }
  let( :user_api    ) { ApiFactory.create_new test_user }
  let( :file_path   ) { "#{Rails.root}/test/files/maven-1.0.1.pom" }
  let( :test_file   ) { Rack::Test::UploadedFile.new(file_path, "text/xml") }

  describe "Unauthorized user shouldnt have access" do
    before(:each) do
      delete "#{root_uri}/sessions"
    end

    it "return 401, when user tries to get project info" do
      get "#{project_uri}/12abcdef12343434.json", nil, "HTTPS" => "on"
      response.status.should eq(401)
    end

    it "returns 401, when user tries to upload file" do
      post project_uri, {upload: test_file, multipart:true, send_file: true}, "HTTPS" => "on"
      response.status.should eq(401)
    end

    it "returns 401, when user tries to delete file" do
      delete project_uri + '/1223335454545324.json', :upload => "123456", "HTTPS" => "on"
      response.status.should eq(401)
    end
  end


  describe "Uploading new project" do
    include Rack::Test::Methods

    it "fails, when upload-file is missing" do
      response = post project_uri, {:api_key => user_api.api_key}, "HTTPS" => "on"
      response.status.should eq(403)
    end

    it "returns 201 and project info, when upload was successfully" do
      response = post project_uri, {
        upload:    test_file,
        api_key:   user_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      response.status.should eq(201)
    end
  end
end
