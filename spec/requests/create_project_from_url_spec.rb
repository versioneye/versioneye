require 'spec_helper'

describe "Create Project from URL" do

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

  it "create a project from URL" do 
    get "/signin", nil, "HTTPS" => "on"
    assert_response :success

    post "/sessions", {:session => {:email => @user1.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to("/user/projects")

    get "/user/projects/new", nil, "HTTPS" => "on"
    assert_response :success
    response.should contain("Create a new project")

    post "/user/projects", {:project => {:url => "https://s3.amazonaws.com/veye_test_env/Gemfile" }}, "HTTPS" => "on"
    assert_response 302
    project = Project.first 
    project.should_not be_nil
    response.should redirect_to("/user/projects/#{project.id.to_s}")
    
    get "/user/projects/#{project.id.to_s}", nil, "HTTPS" => "on"
    response.should contain("Dependencies are Outdated")
    response.should contain("rails")
    response.should contain("jquery-rails")
    response.should contain("therubyracer")
  end

end
