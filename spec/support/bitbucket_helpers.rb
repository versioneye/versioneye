module BitbucketHelpers 
  def connect_account(user)
    visit signin_path
    click_button "Login with Bitbucket"

    #when bitbucket asks testuser's credentials
    within("form.login-form") do
      fill_in "Username", :with => Settings.bitbucket_username
      fill_in 'Password', :with => Settings.bitbucket_password
      click_button 'Log in'
    end
    #grant access
    if page.has_css? 'button.aui-button'
      click_button "Grant access"
    end

    user

  end
end

