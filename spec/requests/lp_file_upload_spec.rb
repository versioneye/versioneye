require 'spec_helper'

describe "Create Project from file uplaod on the service page - guest area" do

  it "create a project from file upload as singned in user." do
    get root_path
    assert_response :success
    response.body.should match("What is VersionEye")

    gemfile = "#{Rails.root}/spec/assets/Gemfile"
    file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
    post "services", {:utf8 => true, :upload => {:datafile => file_attachment }}
    file_attachment.close
    assert_response 302
    project = Project.first
    project.should_not be_nil
    response.should redirect_to( service_path( project ) )

    get service_path( project )
    response.body.should match("Dependencies")
    response.body.should match("rails")
    response.body.should match("jquery-rails")
    response.body.should match("therubyracer")
  end

end
