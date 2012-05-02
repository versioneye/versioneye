require 'spec_helper'

describe "blogs" do
  it "shows the default result for blogs" do
    get "/blogs"
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "a#blog_home"
  end

end