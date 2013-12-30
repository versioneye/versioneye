require 'spec_helper'

describe Notification do

  before(:each) do
    User.destroy_all
    Product.destroy_all
    Notification.destroy_all

    @user         = UserFactory.create_new 1
    @notification = NotificationFactory.create_new @user
  end

  describe "unsent_user_notifications" do

    it "fetches all unsent notifications" do
      NotificationFactory.create_new @user
      NotificationFactory.create_new @user
      NotificationFactory.create_new @user
      notifications = Notification.unsent_user_notifications @user
      notifications.should_not be_nil
      notifications.size.should eq(4)
    end

  end

  describe "remove_notifications" do

    it "fetches all unsent_user_notifications" do
      notifications = Notification.unsent_user_notifications @user
      notifications.should_not be_nil
      notifications.size.should eq(1)
      notifications.first.user_id.should eq( @user.id )

      Notification.remove_notifications( @user )
      notifications = Notification.unsent_user_notifications @user
      notifications.should_not be_nil
      notifications.size.should eq(0)
    end

  end

  describe "send_notifications" do

    it "sends out 2 notifications" do
      user         = UserFactory.create_new 2
      User.count.should eq(2)

      notification = NotificationFactory.create_new user

      notification.user_id.should_not be_nil
      notification.user.should_not be_nil

      Notification.count.should eq(2)

      count = Notification.send_notifications
      count.should eq(2)
    end

    it "sends out 1 notifications, because 1 user is deleted" do
      user         = UserFactory.create_new 3
      NotificationFactory.create_new user
      user.deleted = true
      user.save
      count        = Notification.send_notifications
      count.should eq(1)
    end

  end

end
