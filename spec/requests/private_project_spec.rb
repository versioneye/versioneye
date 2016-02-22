require 'spec_helper'

describe "Private Project" do

  before(:each) do
    @user1 = UserFactory.create_new(100, true)
    @user1.save

    @user2 = UserFactory.create_new(101, true)
    @user2.save

    parser = ComposerParser.new
    @project = parser.parse("https://s3.amazonaws.com/veye_test_env/composer.json")
    @project.user = @user1
    @project.name = "composer.json"
    @project.save
    @project.save_dependencies
  end

  it "ensure that private user projects stay private" do
    get "/signin", nil, "HTTPS" => "on"
    assert_response :success

    post "/sessions", {:session => {:email => @user1.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to( user_projects_path )

    p "GET: /user/projects/#{@project._id.to_s}"
    get "/user/projects/#{@project._id.to_s}"
    assert_response :success
    response.body.should match("symfony/doctrine-bundle")

    get "/signout"

    p "GET: /user/projects/#{@project._id.to_s}"
    get "/user/projects/#{@project._id.to_s}"
    assert_response 302
    response.should redirect_to("/signin")

    post "/sessions", {:session => {:email => @user2.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    response.should redirect_to( user_packages_i_follow_path )

    get "/user/projects/#{@project._id.to_s}"
    assert_response 302
    response.should redirect_to( root_path )

    @project.public = true
    @project.save

    get "/user/projects/#{@project._id.to_s}"
    assert_response :success
    response.body.should     match("symfony/doctrine-bundle")
    response.body.should_not match("Monitor it")
    response.body.should_not match("Send notifications to")
    response.body.should_not match("Delete this project")

    get "/signout"

    get "/user/projects/#{@project._id.to_s}"
    assert_response :success
    response.body.should     match("symfony/doctrine-bundle")
    response.body.should_not match("Monitor it")
    response.body.should_not match("Send notifications to")
    response.body.should_not match("Delete this project")
  end

end
