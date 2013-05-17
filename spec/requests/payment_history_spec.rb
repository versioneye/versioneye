require 'spec_helper'

describe "Payment History" do
  before :each do
    @test_user = UserFactory.default
    @test_user.save
    host!('127.0.0.1:3000')
    
    post "/sessions", 
      {:session => {email: @test_user.email, password: @test_user.password}}, 
      "HTTPS" => "on"
    assert_response 302
    response.should redirect_to("/user/projects")


  end

  after :each do
    @test_user.delete
  end

  describe "when stripe id is missing or is uncorrect", :js => true do
    before :each do
      FakeWeb.register_uri(
        :get, 
        %r|https://api\.stripe\.com/v1/invoices/*|,
        body: <<-JSON
          {
            "object": "list",
            "count": 0,
            "url": "/v1/invoices",
            "data": []
          }
        JSON
      )
    end

    after :each do
      FakeWeb.clean_registry
    end

    it "shows correct message when there's no history" do
       
      get "/settings/payments", nil, "HTTPS" => "on" 
      assert_response :success
      have_css "#payment_history", text: "You dont have any Payment history"
    end
  end

  describe "use correct stripe id", :js => true  do
    before :each do
      @test_user.stripe_customer_id = "cus_1m9PBsr4Xhumds"
      @test_user.save
      url = "https://api.stripe.com/v1/invoices?customer=%s -u %s:" % [@test_user.stripe_customer_id, Stripe.api_key]

      recorded_response = `curl -is #{url}`      
      FakeWeb.register_uri(
        :get, 
        %r|https://api\.stripe\.com/v1/invoices/*|,
        response: recorded_response 
      )
   end

    it "shows correct list of invoices for current user" do
      #visit settings_payments_path;
      get settings_payments_path, nil, "HTTPS" => "on"
      assert_response :success
      have_css "#payment_history"
      
      should_not have_text('Iniatilizing frontend app..')
      save_and_open_page
      response.should have_selector('table tr', :count => 2)
    end
  end

end
