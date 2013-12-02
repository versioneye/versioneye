require 'spec_helper'

describe PromoCode do

  describe "by_name" do

    it "returns nil for nil" do
      PromoCode.by_name(nil).should be_nil
    end

    it "returns promo tada for nil" do
      PromoCode.new({:name => "tada", :free_private_projects => 3}).save
      tada = PromoCode.by_name("tada")
      tada.should_not be_nil
      tada.name.should eq("tada")
      tada.free_private_projects.should eq(3)
      tada.redeemed.should eq(0)
    end

  end

end
