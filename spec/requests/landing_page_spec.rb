require 'spec_helper'

describe "landing page" do

  it "diplays the landing page" do
    get "/"
    assert_response :success
    response.body.should match("VersionEye")
    response.body.should match("notifies you about")
  end

end
