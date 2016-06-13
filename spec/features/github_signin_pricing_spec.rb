require 'spec_helper'

describe "Signin with GitHub" do

  let(:default_user){FactoryGirl.create(:default_user)}

  def logout_github
    visit "https://github.com/logout"
    click_button "Sign out"
  rescue => e
    p e
  end

  before :each do
    User.delete_all
    logout_github
  end

  after :each do
    logout_github
  end


  it "signs in new user with github, the email is not taken yet", js: true do
    User.all.count.should eql(0)
    Plan.create_defaults

    visit pricing_path
    page.has_css? 'pricing_head'
    first('.btn.btn-big.btn-success').click

    page.has_css? 'button.btn-github'
    within("#sm_list") do
      click_button "Login with GitHub (public)"
    end

    # GitHub Login Form
    fill_in "Username or email address", :with => Settings.instance.github_user
    fill_in 'Password', :with => Settings.instance.github_pass
    click_button 'Sign in'

    # Grant access
    if page.has_css?('button-primary') || page.has_css?('button.primary') || page.has_content?('Authorize application')
      click_button "Authorize application"
    end

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
    click_button 'Submit'

    sleep 5

    User.all.count.should eql(1)
    user = User.first
    user.verification.should be_nil
    user.github_scope.should eq("public_repo,user:email")
    user.stripe_token.should_not be_nil
    user.stripe_customer_id.should_not be_nil
    user.plan.should_not be_nil
    user.plan.name_id.should eql(Plan.free_plan.name_id)
  end

end
