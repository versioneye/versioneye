require 'spec_helper'

describe "landing page" do

  it "diplays the landing page" do
    get "/"
    assert_response :success
    assert_select "form[action=?]", "/search"
    assert_select "button[type=?]", "submit"
  end

end
