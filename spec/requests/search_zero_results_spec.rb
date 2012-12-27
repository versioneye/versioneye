require 'spec_helper'

describe "empty_search_result" do

  before(:each) do
    visit root_path
    visit search_path
  end

  it "submits query with empty results" do
    url_string = "http://versioneye.com"
    msg_string = "#1-2-3-test"

    get "/search", {:q => "BullshitBongo"}
    assert_response :success
    assert_select "#newUrlForm"
    visit root_path
    post submitted_urls_path, {:url     => url_string,
                              :message  => msg_string,
                              :user_email    => "admin@versioneye.com",
                              :value_a  => 1,
                              :value_b  => 2,
                              :fb_math  => 3},
                              {'HTTP_REFERER' => search_path}
    assert_response 302
    test_urls = SubmittedUrl.where(:user_email   => "admin@versioneye.com", 
                                  :message => "#1-2-3-test")
    test_urls.should_not be_nil

    test_url = test_urls.last
    test_url.should_not be_nil
    test_url[:url].should eql(url_string)
  end

end