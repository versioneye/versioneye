require 'spec_helper'

describe "empty_search_result" do

  before(:each) do
    visit root_path
    visit search_path
  end

  it "submits query with empty results" do
    user = UserFactory.default
    user.save

    post "/sessions", {:session => {:email => user.email, :password => user.password}}, "HTTPS" => "on"
    assert_response 302 
    response.should redirect_to("/user/projects")

    url_string = "http://versioneye.com"
    msg_string = "#1-2-3-test"

    get "/search", {:q => "BullshitBongo1235"}
    assert_response :success
    assert_select "#newUrlForm"
    visit root_path
    post submitted_urls_path, {:url => url_string, :message => msg_string},
                              {'HTTP_REFERER' => search_path}
    assert_response 302
    test_urls = SubmittedUrl.where(:url => url_string, :message => msg_string)
    test_urls.should_not be_nil

    test_url = test_urls.last
    test_url.should_not be_nil
    test_url[:url].should eql(url_string)
  end

end
