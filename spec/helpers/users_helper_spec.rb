require 'spec_helper'

describe UsersHelper do

  before(:each) do
    @users_controller = UsersController.new
    @users_controller.extend(UsersHelper)
  end

  describe "has_permission_to_see_products" do

    it "has permission. user and current_user are the same!" do
      user = User.new
      user.id = 1
      current_user = user
      @users_controller.has_permission_to_see_products( user, current_user ).should be_truthy
    end

    it "has permission. user privacy is for everybody!" do
      user = User.new
      user.id = 1
      current_user = User.new
      current_user.id = 2
      user.privacy_products = "everybody"
      @users_controller.has_permission_to_see_products( user, current_user ).should be_truthy
    end

    it "has no permission. user privacy is for nobody!" do
      user = User.new
      user.id = 1
      current_user = User.new
      current_user.id = 2
      user.privacy_products = "nobody"
      @users_controller.has_permission_to_see_products( user, current_user ).should be_falsey
    end

    it "has permission. user privacy is for nobody! but user and current_user are the same!" do
      user = User.new
      user.id = 1
      current_user = User.new
      current_user.id = 1
      user.privacy_products = "nobody"
      @users_controller.has_permission_to_see_products( user, current_user ).should be_truthy
    end

    it "has no permission. user privacy is for nobody! current_user is nil" do
      user = User.new
      user.id = 1
      user.privacy_products = "nobody"
      @users_controller.has_permission_to_see_products( user, nil ).should be_falsey
    end

    it "has no permission. user privacy is for registered users only! current_user is nil" do
      user = User.new
      user.id = 1
      user.privacy_products = "ru"
      @users_controller.has_permission_to_see_products( user, nil ).should be_falsey
    end

    it "has permission. user privacy is for registered users only! current_user is not nil" do
      user = User.new
      user.id = 1
      current_user = User.new
      current_user.id = 3
      user.privacy_products = "ru"
      @users_controller.has_permission_to_see_products( user, current_user ).should be_truthy
    end

  end

end
