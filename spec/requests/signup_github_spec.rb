require 'spec_helper'

describe "SignUp with GitHub" do

  it "signup with github" do 
    
    get "/signup", nil, "HTTPS" => "on"
    assert_response :success
    assert_tag :tag => "span", :attributes => { :class => "btn_github login" }

  end

end
