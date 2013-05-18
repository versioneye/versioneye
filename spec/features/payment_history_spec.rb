require 'spec_helper'

describe "Payment History" do

  before :each do
    @test_user = UserFactory.create_new
    @test_user.save

    visit 'http://127.0.0.1:3000/signin'
    fill_in 'session[email]',    :with => @test_user.email
    fill_in 'session[password]', :with => @test_user.password
    click_button 'Sign In'
    page.should have_content("My Projects")
  end

  after :each do
    User.destroy_all
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
      visit "/settings/payments"
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
      visit settings_payments_path
      have_css "#payment_history"
      save_and_open_page
      should_not have_content('Iniatilizing frontend app..')
      # should have_selector('tbody tr', :count => 2)
    end
  end

end
