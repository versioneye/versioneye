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
    Plan.delete_all
    Plan.create_defaults
    orga = OrganisationService.create_new default_user, 'my_orga'

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

    fill_in 'name'    , :with => 'Hans Tanz'
    fill_in 'street'  , :with => 'hanse street 2'
    fill_in 'zip_code', :with => '68199'
    fill_in 'city'    , :with => 'Mannheim'
    fill_in 'email'   , :with => 'giti@hubi.com'
    find('#country').find(:xpath, "option[@value = 'DE']").select_option

    fill_in 'cardnumber', :with => "5105 1051 0510 5100"
    fill_in 'cvc',        :with => "777"
    fill_in 'month',      :with => "10"
    fill_in 'year',       :with => "2017"
    click_button 'Submit'

    sleep 5

    expect( User.all.count ).to eql(1)
    user = User.first
    expect( user.verification ).to be_nil
    expect( user.github_scope ).to eq("public_repo,user:email")

    expect( Organisation.count ).to eq(1)
    orga = Organisation.first
    expect( orga.stripe_token ).to_not be_nil
    expect( orga.stripe_customer_id ).to_not be_nil
    expect( orga.plan ).to_not be_nil
    expect( orga.plan.name_id ).to eql(Plan.free_plan.name_id)
  end

end
