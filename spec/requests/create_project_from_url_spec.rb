require 'spec_helper'

describe "Create Project from URL" do

  before(:each) do
    @user1 = UserFactory.create_new(100, true)
    @user1.save
  end

  it "create a project from URL" do
    get signin_path, nil, "HTTPS" => "on"
    assert_response :success

    post sessions_path, {:session => {:email => @user1.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to( user_packages_i_follow_path )

    get new_user_project_path, nil, "HTTPS" => "on"
    assert_response :success
    response.body.should match("Create a new project")

    post "/user/projects", {:project => {:url => "https://s3.amazonaws.com/veye_test_env/Gemfile" }}, "HTTPS" => "on"
    assert_response 302
    project = Project.first
    project.should_not be_nil
    response.should redirect_to( user_project_path( project ) )

    get user_project_path( project ), nil, "HTTPS" => "on"
    response.body.should match("are outdated and")
    response.body.should match("rails")
    response.body.should match("jquery-rails")
    response.body.should match("therubyracer")
  end

end
