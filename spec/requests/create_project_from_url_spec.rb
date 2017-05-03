require 'spec_helper'

describe "Create Project from URL" do

  before(:each) do
    @user1 = UserFactory.create_new(100, true)
    @user1.save
    Plan.create_defaults
    orga = OrganisationService.create_new_for( @user1 )
    expect( orga.save ).to be_truthy
  end

  it "create a project from URL" do
    get signin_path
    assert_response :success

    post sessions_path, params: {:session => {:email => @user1.email, :password => "12345"}}
    assert_response 302
    response.should redirect_to( projects_organisation_path( Organisation.first ) )

    get new_user_project_path
    assert_response :success
    response.body.should match("Create a new project")

    post "/user/projects", params: {:project => {:url => "https://s3.amazonaws.com/veye_test_env/Gemfile" }}
    assert_response 302
    project = Project.first
    project.should_not be_nil
    response.should redirect_to( user_project_path( project ) )

    get user_project_path( project )
    response.body.should match("outdated.")
    response.body.should match("rails")
    response.body.should match("jquery-rails")
    response.body.should match("therubyracer")
  end

end
