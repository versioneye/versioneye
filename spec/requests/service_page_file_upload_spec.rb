require 'spec_helper'

describe "Create Project from file uplaod on the service page - guest area" do

  before(:each) do
    Project.destroy_all
    Projectdependency.destroy_all
  end

  after(:each) do 
    Project.destroy_all
    Projectdependency.destroy_all
  end

  it "create a project from file upload as singned in user." do 
    get services_path
    assert_response :success
    response.should contain("What is VersionEye")

    gemfile = "#{Rails.root}/spec/assets/Gemfile"
    file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
    post "services", {:utf8 => true, :upload => {:datafile => file_attachment }}
    assert_response 302
    project = Project.first 
    project.should_not be_nil
    response.should redirect_to( service_path( project ) )
    
    get service_path( project )
    response.should contain("Dependencies")
    response.should contain("rails")
    response.should contain("jquery-rails")
    response.should contain("therubyracer")
  end

end
