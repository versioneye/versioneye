require 'spec_helper'

describe "Create Project from file uplaod" do

  before(:each) do
    User.destroy_all
    Project.destroy_all
    Projectdependency.destroy_all

    @user1 = UserFactory.create_new(100, true)
    @user1.save
  end

  after(:each) do 
    User.destroy_all
    Project.destroy_all
    Projectdependency.destroy_all
  end

  it "create a project from file upload as singned in user." do 
    get signin_path, nil, "HTTPS" => "on"
    assert_response :success

    post sessions_path, {:session => {:email => @user1.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to( user_projects_path )

    get new_user_project_path, nil, "HTTPS" => "on"
    assert_response :success
    response.should contain("Create a new project")

    gemfile = "#{Rails.root}/spec/assets/Gemfile"
    file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
    post "/user/projects", {:utf8 => true, :upload => {:datafile => file_attachment }}, "HTTPS" => "on"
    assert_response 302
    project = Project.first 
    project.should_not be_nil
    response.should redirect_to( user_project_path( project ) )
    
    get user_project_path( project ), nil, "HTTPS" => "on"
    response.should contain("Dependencies are Outdated")
    response.should contain("rails")
    response.should contain("jquery-rails")
    response.should contain("therubyracer")
  end

end
