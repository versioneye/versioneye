require 'spec_helper'
describe "Signup from the pricing page" do

  let(:user1){FactoryGirl.build(:user, email: "test@versioneye.com")}

  it "signup a new user from the pricing page", js: true do
    Plan.create_defaults

    visit pricing_path
    page.has_css? 'pricing_head'
    first('.btn.btn-big.btn-success').click

    fill_in 'user[fullname]', :with => 'Hans Tanz'
    fill_in 'user[email]',    :with => 'hans@versioneye.com'
    fill_in 'user[password]', :with => 'hansolo'

    check "terms"
    click_button 'signup_form_btn'

    page.has_content? 'Credit Card Information'

    fill_in 'name'  , :with => 'Hans Tanz'
    fill_in 'street', :with => 'hanse street 2'
    fill_in 'zip_code'   , :with => '68199'
    fill_in 'city'  , :with => 'Mannheim'
    find('#country').find(:xpath, "option[@value = 'DE']").select_option

    fill_in 'cardnumber', :with => "5105 1051 0510 5100"
    fill_in 'cvc',        :with => "777"
    fill_in 'month',      :with => "10"
    fill_in 'year',       :with => "2017"
    click_button 'Save'

    sleep 5

    page.should have_content("Many Thanks. We just updated your plan.")
    user = User.first
    user.stripe_token.should_not be_nil
    user.stripe_customer_id.should_not be_nil
    user.plan.should_not be_nil
    user.plan.name_id.should eql(Plan.micro.name_id)
  end

end
