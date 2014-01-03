require 'spec_helper'

describe UserNotificationSetting do

  describe "fetch_or_create_notification_setting" do

    it "creates a new one" do
      user = UserFactory.create_new
      user.user_notification_setting.should be_nil
      UserNotificationSetting.fetch_or_create_notification_setting user
      user.user_notification_setting.should_not be_nil
      UserNotificationSetting.count.should eq(1)
      uns = UserNotificationSetting.first
      uns.user.email.should eql(user.email)
      user_db = User.first
      user_db.user_notification_setting.should_not be_nil
    end

  end

  describe "send_newsletter_features" do

    it "sends out 0 because user is deleted" do
      user = UserFactory.create_new
      user.deleted = true
      user.save
      UserNotificationSetting.send_newsletter_features.should eq(0)
    end

    it "sends out 0 because user don't want to receive this email" do
      user = UserFactory.create_new
      UserNotificationSetting.fetch_or_create_notification_setting user
      user_notification_setting = user.user_notification_setting
      user_notification_setting.newsletter_features = false
      user_notification_setting.save
      UserNotificationSetting.send_newsletter_features.should eq(0)
    end

    it "sends out 1 because user is not deleted and want to receive the email" do
      UserFactory.create_new
      UserNotificationSetting.send_newsletter_features.should eq(1)
    end

    it "sends out 2" do
      UserFactory.create_new 1
      UserFactory.create_new 2
      UserNotificationSetting.send_newsletter_features.should eq(2)
    end

    it "sends out 2 of 3 because 1 is deleted" do
      user = UserFactory.create_new 1
      user.deleted = true
      user.save
      UserFactory.create_new 2
      UserFactory.create_new 3
      UserNotificationSetting.send_newsletter_features.should eq(2)
    end

  end

end
