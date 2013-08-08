require 'spec_helper'

describe "landing page" do

  it "diplays the landing page" do
    get "/"
    assert_response :success
    assert_select "form[action=?]", "/services"
    assert_select "button[type=?]", "submit"
    assert_select "input[id=?]", "upload_datafile"
  end

end
