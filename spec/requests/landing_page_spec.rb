require 'spec_helper'

describe "landing page" do
  
  it "diplays the landing page" do
    get "/"
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "input[name=?]", "q"
    assert_select "body div.container section"
    assert_select "h1", 2
  end

end