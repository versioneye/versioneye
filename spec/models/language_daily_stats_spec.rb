require 'spec_helper'

describe LanguageDailyStats do
  let(:today_ruby_products){
    FactoryGirl.create_list(:newest, 13,
                             name: FactoryGirl.generate(:product_name_generator),
                             language: "Ruby",
                             version: FactoryGirl.generate(:version_generator),
                             created_at: Date.today.at_midnight)}

  let(:yesterday_ruby_products){
    FactoryGirl.create_list(:newest, 17,
                             name: FactoryGirl.generate(:product_name_generator),
                             version: FactoryGirl.generate(:version_generator),
                             created_at: 1.days.ago.at_midnight)}

  let(:lastweek_ruby_products){
    FactoryGirl.create_list(:newest, 19,
                             name: FactoryGirl.generate(:product_name_generator),
                             version: FactoryGirl.generate(:version_generator),
                             created_at: 7.days.ago.at_midnight)}

  let(:lastmonth_ruby_products){
    FactoryGirl.create_list(:newest, 23,
                             name: FactoryGirl.generate(:product_name_generator),
                             version: FactoryGirl.generate(:version_generator),
                             created_at: (Date.today << 1).at_midnight)}

  let(:twomonth_ruby_products){
    FactoryGirl.create_list(:newest, 29,
                             name: FactoryGirl.generate(:product_name_generator),
                             version: FactoryGirl.generate(:version_generator),
                             created_at: (Date.today << 2).at_midnight)}

  after :each do
    LanguageDailyStats.delete_all
  end

  describe "today_stats" do
    before :each do
      today_ruby_products.first.save
    end

   it "should return all ruby project" do
      LanguageDailyStats.update_counts
      stats = LanguageDailyStats.today_stats
      stats.should_not be_nil
      stats.has_key?('Ruby').should be_true
      stats['Ruby'].has_key?("new_version")
      stats['Ruby']["new_version"].should eq(13)
    end

    #important! It catches double counting today
    it "shoulnt double count today's metrics" do
      yesterday_ruby_products.first.save
      twomonth_ruby_products.first.save
      LanguageDailyStats.update_counts(61)

      stats = LanguageDailyStats.today_stats
      stats.should_not be_nil
      stats.count.should > 0
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(13)

    end
  end

  describe "yesterday_stats" do
    before :each do
      today_ruby_products.first.save
      yesterday_ruby_products.first.save
      LanguageDailyStats.update_counts(2)
    end

    after :each do
      LanguageDailyStats.delete_all
    end


    it "should return all ruby project" do
      stats = LanguageDailyStats.yesterday_stats

      stats.should_not be_nil
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(17)
    end
  end

  describe "current_week_stats" do
    before :each do
      today_ruby_products.first.save
      yesterday_ruby_products.first.save
      LanguageDailyStats.update_counts(3)
    end

    it "should return correct stats for current week" do
      stats =  LanguageDailyStats.current_week_stats

      stats.should_not be_nil
      stats.empty?.should be_false
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      if Time.now.monday?
        # yesterday was Sunday, that's last week
        stats["Ruby"]["new_version"].should eq(13)
      else
        stats["Ruby"]["new_version"].should eq(30)
      end
    end
  end

  describe "last_week_stats" do
    before :each do
      lastweek_ruby_products.first.save
      LanguageDailyStats.update_counts(14)
    end

    it "should return correct stats for last week" do
      stats = LanguageDailyStats.last_week_stats

      stats.should_not be_nil
      stats.empty?.should be_false
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(19)
    end
  end

  describe "current_month_stats" do
    before :each do
      @total_counts = 13
      today_ruby_products.first.save
      if Date.today.day > 1
        yesterday_ruby_products.first.save
        @total_counts += 17
      end
      if Date.today.day > 7
        lastweek_ruby_products.first.save
        @total_counts += 19
      end
      LanguageDailyStats.update_counts(15)
    end

    it "should return correct stats for current month" do
      stats =  LanguageDailyStats.current_month_stats

      stats.should_not be_nil
      stats.empty?.should be_false
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(@total_counts)
    end
  end

  describe "last_month_stats" do
    before :each do
      lastmonth_ruby_products.first.save
      LanguageDailyStats.update_counts(32)
    end

    it "should return correct stats for last month" do
      stats =  LanguageDailyStats.last_month_stats

      stats.should_not be_nil
      stats.empty?.should be_false
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(23)
    end
  end

  describe "two_months_ago_stats" do
    before :each do
      twomonth_ruby_products.first.save
      LanguageDailyStats.update_counts(64)
    end

    it "should return correct stats for two month ago" do
      stats =  LanguageDailyStats.two_months_ago_stats

      stats.should_not be_nil
      stats.empty?.should be_false
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(29)
    end
  end
end
