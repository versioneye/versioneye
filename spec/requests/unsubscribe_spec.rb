require 'spec_helper'

describe "unsubscribe" do

  context "unsubscribe" do

    it "does not unsubscribe because no user" do
      user = UserFactory.create_new 1
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.newsletter_features.should be_truthy

      get "/unsubscribe/NAN/newsletter_features", nil, "HTTPS" => "on"
      assert_response :success

      user = User.find user.id 
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.newsletter_features.should be_truthy
    end

    it "unsubscribes from newsletter_news" do
      user = UserFactory.create_new 1
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.newsletter_news.should be_truthy

      email = user.email.unpack("H*").first

      get "/unsubscribe/#{email}/newsletter_news", nil, "HTTPS" => "on"
      assert_response :success

      user = User.find user.id 
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.newsletter_news.should be_falsey
    end

    it "unsubscribes from newsletter_features" do
      user = UserFactory.create_new 1
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.newsletter_features.should be_truthy

      email = user.email.unpack("H*").first

      get "/unsubscribe/#{email}/newsletter_features", nil, "HTTPS" => "on"
      assert_response :success

      user = User.find user.id 
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.newsletter_features.should be_falsey
    end

    it "unsubscribes from notification_emails" do
      user = UserFactory.create_new 1
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.notification_emails.should be_truthy

      email = user.email.unpack("H*").first

      get "/unsubscribe/#{email}/notification_emails", nil, "HTTPS" => "on"
      assert_response :success

      user = User.find user.id 
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.notification_emails.should be_falsey
    end

    it "unsubscribes from project_emails" do
      user = UserFactory.create_new 1
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.project_emails.should be_truthy

      email = user.email.unpack("H*").first

      get "/unsubscribe/#{email}/project_emails", nil, "HTTPS" => "on"
      assert_response :success

      user = User.find user.id 
      uns = UserNotificationSetting.fetch_or_create_notification_setting user
      uns.project_emails.should be_falsey
    end

  end

end
