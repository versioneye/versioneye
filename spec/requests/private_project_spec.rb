require 'spec_helper'

describe "Private Project" do

  before(:each) do
    @user1 = UserFactory.create_new(100, true)
    @user1.save

    @user2 = UserFactory.create_new(101, true)
    @user2.save

    parser = ComposerParser.new
    @project = parser.parse("https://s3.amazonaws.com/veye_test_env/composer.json")
    @project.user_id = @user1._id.to_s
    @project.name = "composer.json"
    @project.project_key = "composer_hutzi_1"
    @project.save
    @project.save_dependencies
  end

  after(:each) do 
    @user1.delete
    @user2.delete
    @project.delete
  end

  it "ensure that private user projects stay private" do 
    get "/signin", nil, "HTTPS" => "on"
    assert_response :success

    post "/sessions", {:session => {:email => @user1.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to("/user/projects")

    get "/user/projects/#{@project._id.to_s}"
    assert_response :success
    response.should contain("symfony/doctrine-bundle")

    get "/signout"

    get "/user/projects/#{@project._id.to_s}"
    assert_response 302
    response.should redirect_to("/signin")

    post "/sessions", {:session => {:email => @user2.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to("/user/projects")

    get "/user/projects/#{@project._id.to_s}"
    assert_response 302
    response.should redirect_to("/")

    @project.public = true 
    @project.save 

    get "/user/projects/#{@project._id.to_s}"
    assert_response :success
    response.should contain("symfony/doctrine-bundle")
    response.should_not contain("Monitor it")
    response.should_not contain("Send notifications to")
    response.should_not contain("Delete this project")

    get "/signout"

    get "/user/projects/#{@project._id.to_s}"
    assert_response :success
    response.should contain("symfony/doctrine-bundle")
    response.should_not contain("Monitor it")
    response.should_not contain("Send notifications to")
    response.should_not contain("Delete this project")
  end

end
