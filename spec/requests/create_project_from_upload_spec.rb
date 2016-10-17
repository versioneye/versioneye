require 'spec_helper'

describe "Create Project from file uplaod" do

  before(:each) do
    @user1 = UserFactory.create_new(100, true)
    @user1.save
    Plan.create_defaults
    orga = OrganisationService.create_new_for( @user1 )
    expect( orga.save ).to be_truthy
  end

  it "create a project from file upload as singned in user." do
    get signin_path, nil, "HTTPS" => "on"
    assert_response :success

    post sessions_path, {:session => {:email => @user1.email, :password => "12345"}}, "HTTPS" => "on"
    assert_response 302
    expect( response ).to redirect_to( projects_organisation_path( Organisation.first ) )

    get new_user_project_path, nil, "HTTPS" => "on"
    assert_response :success
    expect( response.body ).to match("Create a new project")

    gemfile = "#{Rails.root}/spec/assets/Gemfile"
    file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
    post "/user/projects", {:utf8 => true, :upload => {:datafile => file_attachment }}, "HTTPS" => "on"
    file_attachment.close
    assert_response 302
    project = Project.first
    expect( project ).to_not be_nil
    expect( response ).to redirect_to( user_project_path( project ) )

    get user_project_path( project ), nil, "HTTPS" => "on"
    expect( response.body ).to match("Gemfile")
    expect( response.body ).to match("rails")
    expect( response.body ).to match("jquery-rails")
    expect( response.body ).to match("therubyracer")
    expect( response.body ).to match("outdated")
  end

end
