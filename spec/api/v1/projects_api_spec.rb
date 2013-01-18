require 'spec_helper'
require 'rest_client'

describe VersionEye::ProjectsApi do
  before(:each) do
    @host = "http://127.0.0.1:3000"
    @root_uri = "/api/v1"
    @project_uri = "/api/v1/projects"
    @test_user = UserFactory.create_new 100
    @user_api = ApiFactory.create_new @test_user
  end

  after(:each) do
    @test_user.remove
    @user_api.remove
  end

  describe "Unauthorized user shouldnt have access" do
    before(:each) do
      delete "#{@root_uri}/sessions"
    end

    it "return 401, when user tryes to get project info" do
      get @project_uri + '/12abcdef12343434.json'
      response.status.should == 401
    end

    it "returns 401, when user tries to upload file" do
      post @project_uri, :upload => "1234566"
      response.status.should == 401
    end

    it "returns 401, when user tries to delete file" do
      delete @project_uri + '/1223335454545324.json', :upload => "123456"
      response.status.should == 401
    end

  end


  describe "Uploading new project" do
    include Rack::Test::Methods
    @new_project = nil

    before(:each) do
      file_path =  "#{Rails.root}/test/files/maven-1.0.1.pom"
      @test_file = Rack::Test::UploadedFile.new(file_path, "text/xml")
    end

    it "fails, when upload-file is missing" do
      post @project_uri, :api_key => @user_api.api_key
      response.status.should == 400
    end

    it "returns 201 and project info, when upload was successfully" do
      full_url = "#{@host}#{@project_uri}"
      r = RestClient.post "#{@host}#{@root_uri}/sessions", 
          {
            'api_key' => @user_api.api_key, 
            :multipart => true
          }
      r.code.should eql(201)
      r = RestClient.post full_url, {
        :upload => @test_file, 
        :api_key => @user_api.api_key,
        :multipart => true
      }
      r.code.should eql(201)
      #post @project_uri, upload: @test_file, send_file: true
      #pp response
    end
  end
end
