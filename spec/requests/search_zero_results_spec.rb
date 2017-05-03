require 'spec_helper'

describe "empty_search_result" do

  it "submits query with empty results" do
    Plan.create_defaults
    get root_path

    user = FactoryGirl.create(:default_user)

    post "/sessions", params: {:session => {:email => user.email, :password => user.password}}
    assert_response 302
    response.should redirect_to( projects_organisation_path( Organisation.first ) )

    url_string = "http://versioneye.com"
    msg_string = "#1-2-3-test"

    get "/search", params: {:q => "BullshitBongo1235"}
    assert_response :success
    assert_select "#newUrlForm"
    get root_path
    post submitted_urls_path, params: {:url => url_string, :message => msg_string},
                              headers: {'HTTP_REFERER' => search_path}
    assert_response 302
    test_urls = SubmittedUrl.where(:url => url_string, :message => msg_string)
    test_urls.should_not be_nil

    test_url = test_urls.last
    test_url.should_not be_nil
    test_url[:url].should eql(url_string)
  end

end
