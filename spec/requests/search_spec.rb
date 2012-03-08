require 'spec_helper'

describe "search" do
  it "shows the default search" do
    post "/search", :q => ""
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "body div.container section"
    assert_select "div#searchresults"
  end
end