require 'spec_helper'

describe Follower do
  
  before(:each) do
    @user = User.new
  end
  
  describe "find_notifications_by_user_id" do
    
    it "returns nil. Id not valid." do
      result = Follower.find_notifications_by_user_id(3444)
      result.count.should eql(0)
    end
    
  end
  
end