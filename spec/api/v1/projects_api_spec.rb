require 'spec_helper'
require 'rest_client'

describe VersionEye::ProjectsApi do

  let( :root_uri    ) { "/api/v1" }
  let( :project_uri ) { "/api/v1/projects" }
  let( :test_user   ) { UserFactory.create_new(90) }
  let( :user_api    ) { ApiFactory.create_new test_user }
  let( :file_path   ) { "#{Rails.root}/spec/files/maven-1.0.1.pom" }
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


  describe "Uploading new project as authorized user" do
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

  describe "Accessing not-existing project as authorized user" do

    it "fails when authorized user uses project key that don exist" do
      get "#{@project_uri}/kill_koll_bug_on_loll.json", {
        api_key: @user_api.api_key
      }

      response.status.should eq(400)
    end
  end

  describe "Accessing existing project as authorized user" do
    include Rack::Test::Methods

    before(:each) do
      file_path =  "#{Rails.root}/test/files/Gemfile.lock"
      @test_file = Rack::Test::UploadedFile.new(file_path, "text/xml")
      response = post @project_uri, {
        upload: @test_file,
        api_key: @user_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"

      response.status.should eq(201)
      @project_info = JSON.parse response.body
    end

    it "returns correct project info for existing project" do
      project_key = @project_info["project_key"]
      
      response = get "#{@project_uri}/#{project_key}.json", {
        api_key: @user_api.api_key
      }
      response.status.should eq(200)
      project_info2 = JSON.parse response.body
      project_info2["project_key"].should eq(project_key)
      project_info2["name"].should eq(@project_info["name"])
      project_info2["source"].should eq("upload")
      project_info2["dependencies"].count.should eql(7)
    end

    it "return correct licence info for existing project" do
      project_key = @project_info["project_key"]
      response = get "#{@project_uri}/#{project_key}/licenses.json"
      response.status.should eql(200)

      data = JSON.parse response.body
      data["success"].should be_true
      MIT_licences = data["licenses"]["MIT"].map {|x| x['name']}
      MIT_licences = unknown_licences.to_set
      MIT_licences.include?("daemons").should be_true
      MIT_licences.include?("rack").should be_true
      MIT_licences.include?("tilt").should be_true
      
      ruby_licences = data["licenses"]["Ruby"].map {|x| x['name']}
      ruby_licences = unknown_licences.to_set
      ruby_licences.include?("eventmachine").should be_true
      ruby_licences.include?("thin").should be_true

      unknown_licences = data["licenses"]["unknown"].map {|x| x['name']}
      unknown_licences = unknown_licences.to_set
      unknown_licences.include?("rack-protection").should be_true
      unknown_licences.include?("sinatra").should be_true
   end

    it "deletes existing project successfully" do
      response = delete "#{@project_uri}/#{@project_info['project_key']}.json"
      response.status.should eql(200)
      msg = JSON.parse response.body
      msg["success"].should be_true
    end
  end

end

