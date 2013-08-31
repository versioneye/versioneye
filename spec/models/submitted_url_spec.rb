require 'spec_helper'

describe SubmittedUrl do
  describe 'find_by_id' do
    before(:each) do
      @submitted_url = SubmittedUrlFactory.create_new
    end

    it 'return nil, when parameter `id` is nil' do
      SubmittedUrl.find_by_id(nil).should be_nil
    end

    it 'return nil, when given id dont exist' do
      SubmittedUrl.find_by_id("cibberish-cabberish-bingo-mongo-kongo").should be_nil
    end

    it 'returns object with same id, when given ID exists in db'  do
      @submitted_url.reload
      result = SubmittedUrl.find_by_id(@submitted_url._id)
      result.should_not be_nil
      result._id.to_s.should eql(@submitted_url._id.to_s)
    end
  end

  describe 'user' do
      before(:each) do
        @url_without_userid = SubmittedUrlFactory.create_new
        @test_user = UserFactory.create_new(2)
        @url_with_userid = SubmittedUrlFactory.create_new(user_id: @test_user._id)
      end

      after(:each) do
        @url_without_userid.delete
        @test_user.delete
        @url_with_userid.delete
      end

      it 'returns nil, submittedUrl dont have user information' do
        @url_without_userid.user.should be_nil
      end

      it 'returns correct User when user_id exists' do
          user = @url_with_userid.user
          user.should_not be_nil
          user._id.to_s.should eql(@test_user._id.to_s)
      end
  end

  describe 'update_integration_status' do
    before(:each) do
      @submitted_url1           = SubmittedUrlFactory.create_new(user_email: "t1@test.com")
      @resource_without_product = ProductResourceFactory.create_new({:submitted_url => @submitted_url1})

      @test_user_2           = UserFactory.create_new(2)
      @submitted_url2        = SubmittedUrlFactory.create_new(user_id: @test_user_2._id.to_s)
      @product               = ProductFactory.create_new(:maven)
      @resource_with_product = ProductResourceFactory.create_new({
                                  :submitted_url => @submitted_url2,
                                  :prod_key => @product.prod_key,
                                  :language => @product.language})
    end

    after(:each) do
      @submitted_url1.delete
      @submitted_url2.delete
      @resource_without_product.delete
      @product.delete
      @resource_with_product.delete
      @test_user_2.delete
    end

    it 'returns false when updating fails' do
      @submitted_url1.update_integration_status.should be_false
    end

    it 'returns true when updating is successful' do
      @submitted_url2.update_integration_status.should be_true
    end

  end

end
