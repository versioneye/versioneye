require 'spec_helper'

describe Newest do
  let(:today_ruby_products){
    FactoryGirl.create_list(:newest, 13, 
                             name: FactoryGirl.generate(:product_name_generator),
                             language: "Ruby",
                             prod_type: "gem",
                             version: FactoryGirl.generate(:version_generator),
                             created_at: Date.today.at_midnight)
  }
  let(:yesterday_ruby_products){
    FactoryGirl.create_list(:newest, 17, 
                             name: FactoryGirl.generate(:product_name_generator),
                             language: "Ruby",
                             prod_type: "gem",
                             version: FactoryGirl.generate(:version_generator),
                             created_at: 1.days.ago.at_midnight)
  }


  describe "since_to" do
    it "should return all newest todays packages" do
      today_ruby_products.first.save

      rows = Newest.since_to(0.days.ago.at_midnight, -1.days.ago.at_midnight)
      rows.count.should == 13
    end

    it "should return all yesterdays packages" do
      yesterday_ruby_products.first.save

      rows = Newest.since_to(1.days.ago.at_midnight, 0.days.ago.at_midnight)
      rows.count.should == 17
    end
  end

end
