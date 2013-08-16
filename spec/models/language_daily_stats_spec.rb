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

  describe "metric_not_updated_in_days" do
    after :each do
      LanguageDailyStats.delete_all
    end

    it "should return 0 when newest collection is empty and there's no daily_counts" do
       LanguageDailyStats.metric_not_updated_in_days('new_version').should == 0
    end

    it "should return 1 when last updat was today" do
      today_ruby_products.first.save
      LanguageDailyStats.update_counts
      LanguageDailyStats.metric_not_updated_in_days('new_version').should eq(1)
    end

    it "should return 2 when last update was yesterday" do
      yesterday_ruby_products.first.save
      LanguageDailyStats.update_counts
      LanguageDailyStats.metric_not_updated_in_days('new_version').should eq(2)
    end

    it "should return 8 when last update was in last week" do
      lastweek_ruby_products.first.save
      LanguageDailyStats.update_counts
      LanguageDailyStats.metric_not_updated_in_days('new_version').should eq(8)
    end

    it "should be bigger than 30 when last update was in last month" do
      lastmonth_ruby_products.first.save
      LanguageDailyStats.update_counts
      LanguageDailyStats.metric_not_updated_in_days('new_version').should > 30
    end

    it "should be bigger when last update was in 2months ago month" do
      twomonth_ruby_products.first.save
      LanguageDailyStats.update_counts
      LanguageDailyStats.metric_not_updated_in_days('new_version').should > 60
    end

    it "should be 1 when metrics was  updated today, yesterday and 2months ago month" do
      today_ruby_products.first.save
      yesterday_ruby_products.first.save
      twomonth_ruby_products.first.save
      LanguageDailyStats.update_counts
      LanguageDailyStats.metric_not_updated_in_days('new_version').should == 1
    end


    it "should be 2 when update db as data from yesterday and 2months ago month" do
      yesterday_ruby_products.first.save
      twomonth_ruby_products.first.save
      LanguageDailyStats.update_counts
      LanguageDailyStats.metric_not_updated_in_days('new_version').should == 2
    end

  end

  describe "today_stats" do
    before :each do
      today_ruby_products.first.save
    end


   it "should return all ruby project" do
      LanguageDailyStats.update_counts
      stats = LanguageDailyStats.today_stats
      stats.should_not be_nil
      stats.count.should > 0
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(13)
    end

    #important! It catches double counting today
    it "shoulnt double count today's metrics" do
      yesterday_ruby_products.first.save
      twomonth_ruby_products.first.save
      LanguageDailyStats.update_counts

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
      LanguageDailyStats.update_counts
    end

    after :each do
      LanguageDailyStats.delete_all
    end


    it "should return all ruby project" do
      stats = LanguageDailyStats.yesterday_stats

      stats.should_not be_nil
      stats.count.should > 0
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(17)
    end
  end

  describe "current_week_stats" do
    before :each do
      today_ruby_products.first.save
      yesterday_ruby_products.first.save
      LanguageDailyStats.update_counts
    end

    it "should return correct stats for current week" do
      stats =  LanguageDailyStats.current_week_stats

      stats.should_not be_nil
      stats.empty?.should be_false
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(30)
    end
  end

  describe "last_week_stats" do
    before :each do
      lastweek_ruby_products.first.save
      LanguageDailyStats.update_counts
    end

    it "should return correct stats for current week" do
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
      LanguageDailyStats.update_counts
    end

    it "should return correct stats for current week" do
      p "#{Newest.all.count} / #{Newest.count}"
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
      LanguageDailyStats.update_counts
    end

    it "should return correct stats for current week" do
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
      LanguageDailyStats.update_counts
    end

    it "should return correct stats for current week" do
      stats =  LanguageDailyStats.two_months_ago_stats

      stats.should_not be_nil
      stats.empty?.should be_false
      stats.has_key?("Ruby").should be_true
      stats["Ruby"].has_key?("new_version")
      stats["Ruby"]["new_version"].should eq(29)
    end
  end
end
