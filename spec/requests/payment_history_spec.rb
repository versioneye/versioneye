require 'spec_helper'

describe "Payment History" do
  before :each do
    @test_user = UserFactory.default 
  end

  after :each do
    @test_user.delete
  end

  it "shows correct message when there's no history" do
   
    post "/sessions", 
      {:session => {email: @test_user.email, password: @test_user.password}}, 
      "HTTPS" => "on"
    assert_response 302
    response.should redirect_to("/user/projects")

    get "/settings/payments" 
    p response.body
    assert_response :success
    have_css "#payment_history", text: "You dont have any Payment history"
    Launchy.open("127.0.0.1:3000/settings/payments")
  end

  describe "when user id is missing or is uncorrect" do
    before :each do
      recorded_response = "curl https://api.stripe.com/v1/invoices/ -u sk_test_mkGsLqEW6SLnZa487HYfJVLf:"
      FakeWeb.register_uri(
        :get, 
        %r|https://api\.stripe\.com/v1/invoices/*|,
        body: recorded_response 
      )
    end

    after :each do
      FakeWeb.clean_registry
    end

  end

end
